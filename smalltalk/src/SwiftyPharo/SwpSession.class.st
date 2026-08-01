"
Serves one embedding host. Results stay alive here, keyed by handle, so the host
can walk an object's views long after the expression that produced it returned.
"
Class {
	#name : 'SwpSession',
	#superclass : 'Object',
	#instVars : [
		'objectsByHandle',
		'nextHandle',
		'workspace'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'initialization' }
SwpSession >> initialize [
	super initialize.
	objectsByHandle := Dictionary new.
	nextHandle := 0.
	workspace := SwpWorkspace new
]

{ #category : 'handles' }
SwpSession >> handleFor: anObject [
	nextHandle := nextHandle + 1.
	objectsByHandle at: nextHandle put: anObject.
	^ nextHandle
]

{ #category : 'handles' }
SwpSession >> objectAt: aHandle [
	^ objectsByHandle at: aHandle
]

{ #category : 'handles' }
SwpSession >> release: aHandle [
	objectsByHandle removeKey: aHandle ifAbsent: [ nil ]
]

{ #category : 'requests' }
SwpSession >> handleRequestJson: aString [
	^ STONJSON toString: ([ self handleRequest: (STONJSON fromString: aString) ]
		on: Error
		do: [ :e |
			| failure |
			failure := Dictionary new
				at: #error put: e class name;
				at: #message put: (e messageText ifNil: [ '' ]);
				yourself.
			(e isKindOf: SwpEvaluationError) ifTrue: [
				failure at: #position put: e position ].
			failure ])
]

{ #category : 'requests' }
SwpSession >> handleRequest: aDictionary [
	| operation |
	operation := aDictionary at: #op.
	operation = 'evaluate' ifTrue: [ ^ self evaluate: (aDictionary at: #source) ].
	operation = 'views' ifTrue: [ ^ self viewsOf: (aDictionary at: #handle) ].
	operation = 'items' ifTrue: [ ^ self itemsOf: aDictionary ].
	operation = 'send' ifTrue: [ ^ self sendOf: aDictionary ].
	operation = 'release' ifTrue: [ ^ self releaseOf: (aDictionary at: #handle) ].
	operation = 'complete' ifTrue: [ ^ self completeOf: aDictionary ].
	operation = 'classReferences' ifTrue: [ ^ self classReferencesOf: (aDictionary at: #source) ].
	operation = 'methodReferences' ifTrue: [ ^ self methodReferencesOf: aDictionary ].
	operation = 'styleSource' ifTrue: [ ^ self styleSourceOf: aDictionary ].
	operation = 'undeclaredVariables' ifTrue: [ ^ self undeclaredVariablesOf: (aDictionary at: #source) ].
	operation = 'defineClass' ifTrue: [ ^ self defineClassOf: aDictionary ].
	operation = 'serialize' ifTrue: [ ^ self serializeOf: (aDictionary at: #handle) ].
	operation = 'materialize' ifTrue: [ ^ self materializeOf: (aDictionary at: #data) ].
	operation = 'classBrowser' ifTrue: [ ^ self classBrowserOf: (aDictionary at: #handle) ].
	operation = 'classOf' ifTrue: [ ^ self classOf: (aDictionary at: #handle) ].
	operation = 'compileMethod' ifTrue: [ ^ self compileMethodOf: aDictionary ].
	^ self error: 'unknown op: ', operation
]

{ #category : 'requests' }
SwpSession >> evaluate: aString [
	^ self describe: (Smalltalk compiler requestor: workspace; source: aString; evaluate)
]

{ #category : 'requests' }
SwpSession >> serializeOf: aHandle [
	^ Dictionary new
		at: #data put: (FLSerializer serializeToByteArray: (self objectAt: aHandle)) base64Encoded;
		yourself
]

{ #category : 'requests' }
SwpSession >> materializeOf: aString [
	^ self describe: (FLMaterializer materializeFromByteArray: aString base64Decoded)
]

{ #category : 'requests' }
SwpSession >> classBrowserOf: aHandle [
	| class |
	class := self objectAt: aHandle.
	^ Dictionary new
		at: #name put: class name asString;
		at: #superclass put: (class superclass ifNil: [ '' ] ifNotNil: [ :s | s name asString ]);
		at: #package put: class package name asString;
		at: #tag put: class swpTag;
		at: #definition put: class definitionString asString;
		at: #comment put: (class comment ifNil: [ '' ]) asString;
		at: #methods put: (class swpMethods collect: [ :method | self describeMethod: method ]) asArray;
		yourself
]

{ #category : 'requests' }
SwpSession >> classOf: aHandle [
	^ self describe: (self objectAt: aHandle) class
]

{ #category : 'requests' }
SwpSession >> compileMethodOf: aDictionary [
	| class target selector |
	class := self objectAt: (aDictionary at: #handle).
	target := (aDictionary at: #side) = 'class'
		ifTrue: [ class class ]
		ifFalse: [ class ].
	selector := target
		compile: (aDictionary at: #source)
		classified: (aDictionary at: #category).
	^ self describeMethod: (target >> selector)
]

{ #category : 'requests' }
SwpSession >> describeMethod: aMethod [
	^ Dictionary new
		at: #selector put: aMethod selector asString;
		at: #side put: (aMethod methodClass isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ]);
		at: #category put: aMethod protocol name asString;
		at: #source put: aMethod sourceCode;
		yourself
]

{ #category : 'requests' }
SwpSession >> viewsOf: aHandle [
	^ Dictionary new
		at: #views put: (SwpViewCollector declarationsFor: (self objectAt: aHandle));
		yourself
]

{ #category : 'requests' }
SwpSession >> itemsOf: aDictionary [
	| view |
	view := self viewOf: aDictionary.
	^ Dictionary new
		at: #total put: view totalItems;
		at: #items put: (view itemsFrom: (aDictionary at: #from) count: (aDictionary at: #count)) asArray;
		yourself
]

{ #category : 'requests' }
SwpSession >> sendOf: aDictionary [
	| view |
	view := self viewOf: aDictionary.
	^ self describe: (view sentItemAt: (aDictionary at: #index))
]

{ #category : 'requests' }
SwpSession >> releaseOf: aHandle [
	self release: aHandle.
	^ Dictionary new at: #released put: aHandle; yourself
]

{ #category : 'requests' }
SwpSession >> completeOf: aDictionary [
	| source position cursor tokenStart token selectors |
	source := aDictionary at: #source.
	position := aDictionary at: #position.
	cursor := SwpCompletionCursor source: source position: position.
	tokenStart := cursor completionTokenStart.
	token := cursor completionToken.
	token isEmpty ifTrue: [ ^ self anyCompletionOf: source position: position tokenStart: tokenStart ].
	selectors := Set new.
	selectors addAll: (self unaryCompletionsAt: tokenStart token: token in: source).
	selectors addAll: (self keywordCompletionsAt: tokenStart token: token in: source).
	selectors isEmpty ifTrue: [ ^ self anyCompletionOf: source position: position tokenStart: tokenStart ].
	^ Dictionary new
		at: #tokenStart put: tokenStart;
		at: #completions put: selectors asSortedCollection asArray;
		yourself
]

{ #category : 'requests' }
SwpSession >> unaryCompletionsAt: tokenStart token: aToken in: aString [
	| message behavior |
	message := (OCParser parseFaultyExpression: aString) allChildren
		detect: [ :node |
			node isMessage and: [
				node keywordsPositions notEmpty and: [ node keywordsPositions first = tokenStart ] ] ]
		ifNone: [ ^ #() ].
	behavior := self behaviorOfReceiver: message receiver.
	behavior ifNil: [ ^ #() ].
	^ self selectorsOf: behavior startingWith: aToken
]

{ #category : 'requests' }
SwpSession >> keywordCompletionsAt: tokenStart token: aToken in: aString [
	| candidates message behavior accumulated next |
	candidates := (OCParser parseFaultyExpression: aString) allChildren select: [ :node |
		node isMessage and: [
			node isKeyword and: [
				node keywordsPositions last < tokenStart and: [
					(self behaviorOfReceiver: node receiver) notNil ] ] ] ].
	candidates isEmpty ifTrue: [ ^ #() ].
	message := candidates detectMax: [ :each | each keywordsPositions last ].
	behavior := self behaviorOfReceiver: message receiver.
	accumulated := message selector asString.
	next := Set new.
	behavior allSelectors do: [ :selector | | rest keyword |
		(selector beginsWith: accumulated) ifTrue: [
			rest := selector asString allButFirst: accumulated size.
			rest ifNotEmpty: [
				keyword := (rest copyUpTo: $:) , ':'.
				(keyword beginsWith: aToken) ifTrue: [ next add: keyword ] ] ] ].
	^ next asArray
]

{ #category : 'requests' }
SwpSession >> behaviorOfReceiver: aNode [
	^ self receiverBehaviorOf: aNode in: nil
]

{ #category : 'requests' }
SwpSession >> selectorsOf: aBehavior startingWith: aToken [
	^ ((aBehavior allSelectors select: [ :selector | selector beginsWith: aToken ]) asSortedCollection
		collect: [ :selector | selector asString ]) asArray
]

{ #category : 'requests' }
SwpSession >> anyCompletionOf: aString position: aPosition tokenStart: tokenStart [
	| cursor context |
	cursor := SwpCompletionCursor source: aString position: aPosition.
	context := CoCompletionContext engine: cursor class: Object source: aString position: aPosition.
	^ Dictionary new
		at: #tokenStart put: tokenStart;
		at: #completions put: ((context entries collect: [ :each | each contents asString ]) asArray);
		yourself
]

{ #category : 'requests' }
SwpSession >> classReferencesOf: aString [
	| references |
	references := Dictionary new.
	(OCParser parseFaultyExpression: aString) allChildren
		select: [ :node | self classReferredToBy: node ]
		thenDo: [ :node |
			references
				at: node start
				put: (Dictionary new
					at: #name put: node name asString;
					at: #start put: node start;
					at: #stop put: node stop;
					yourself) ].
	^ Dictionary new
		at: #references put: (references keys asSortedCollection collect: [ :start | references at: start ]) asArray;
		yourself
]

{ #category : 'requests' }
SwpSession >> methodReferencesOf: aDictionary [
	| self_class references |
	self_class := (aDictionary at: #selfClass ifAbsent: [ nil ])
		ifNotNil: [ :name | Smalltalk globals at: name asSymbol ifAbsent: [ nil ] ].
	references := OrderedCollection new.
	(OCParser parseFaultyExpression: (aDictionary at: #source)) allChildren
		do: [ :node | node isMessage ifTrue: [ self referenceOf: node in: self_class into: references ] ].
	^ Dictionary new at: #references put: references asArray; yourself
]

{ #category : 'requests' }
SwpSession >> referenceOf: aMessage in: aSelfClass into: references [
	| behavior method |
	behavior := self receiverBehaviorOf: aMessage receiver in: aSelfClass.
	behavior ifNil: [ ^ self ].
	method := behavior lookupSelector: aMessage selector.
	method ifNil: [ ^ self ].
	references add: (Dictionary new
		at: #selector put: aMessage selector asString;
		at: #stop put: aMessage keywordsPositions last + aMessage selectorParts last size - 1;
		at: #class put: method methodClass instanceSide name asString;
		at: #side put: (method methodClass isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ]);
		at: #category put: method protocol name asString;
		at: #source put: method sourceCode;
		yourself)
]

{ #category : 'requests' }
SwpSession >> receiverBehaviorOf: aReceiver in: aSelfClass [
	| name |
	aReceiver isLiteralNode ifTrue: [ ^ aReceiver value class ].
	aReceiver isMessage ifTrue: [ ^ self behaviorOfSend: aReceiver in: aSelfClass ].
	aReceiver isVariable ifFalse: [ ^ nil ].
	name := aReceiver name asString.
	(name = 'self' and: [ aSelfClass notNil ]) ifTrue: [ ^ aSelfClass ].
	(name = 'super' and: [ aSelfClass notNil ]) ifTrue: [ ^ aSelfClass superclass ].
	^ (self globalBehaviorOf: name) ifNil: [ self workspaceBehaviorOf: name ]
]

{ #category : 'requests' }
SwpSession >> behaviorOfSend: aMessage in: aSelfClass [
	"A send whose selector makes an instance answers one of its receiver class,
	so `ZnClient new get: url` finds get: on ZnClient. Other sends answer nothing,
	since a return type is not ours to know."

	(#( new new: basicNew basicNew: ) includes: aMessage selector) ifFalse: [ ^ nil ].
	^ (self receiverBehaviorOf: aMessage receiver in: aSelfClass) ifNotNil: [ :behavior |
		  behavior isMeta ifTrue: [ behavior instanceSide ] ]
]

{ #category : 'requests' }
SwpSession >> globalBehaviorOf: aName [
	^ (Smalltalk globals at: aName asSymbol ifAbsent: [ nil ])
		ifNotNil: [ :global | global isBehavior ifTrue: [ global class ] ]
]

{ #category : 'requests' }
SwpSession >> workspaceBehaviorOf: aName [
	(workspace bindings includesKey: aName) ifFalse: [ ^ nil ].
	^ (workspace bindings at: aName) ifNotNil: [ :value | value class ]
]

{ #category : 'requests' }
SwpSession >> styleSourceOf: aDictionary [
	| ast spans |
	ast := (aDictionary at: #isMethod)
		ifTrue: [ OCParser parseFaultyMethod: (aDictionary at: #source) ]
		ifFalse: [ OCParser parseFaultyExpression: (aDictionary at: #source) ].
	spans := OrderedCollection new.
	(aDictionary at: #isMethod) ifTrue: [ self styleMethodPattern: ast into: spans ].
	self styleNode: ast into: spans.
	self styleBracketsOf: (aDictionary at: #source) into: spans.
	^ Dictionary new at: #spans put: spans asArray; yourself
]

{ #category : 'requests' }
SwpSession >> styleMethodPattern: aMethodNode into: spans [
	(aMethodNode isKindOf: OCMethodNode) ifFalse: [ ^ self ].
	aMethodNode selectorParts with: aMethodNode keywordsPositions do: [ :part :position |
		spans add: (self boldSpanFrom: position to: position + part size - 1) ]
]

{ #category : 'requests' }
SwpSession >> styleBracketsOf: aString into: spans [
	| palette depth index |
	palette := self parenthesesColors.
	depth := 0.
	index := 1.
	[ index <= aString size ] whileTrue: [
		| character |
		character := aString at: index.
		('([{' includes: character)
			ifTrue: [
				depth := depth + 1.
				spans add: (self spanFrom: index to: index color: (palette at: (depth - 1) \\ palette size + 1)) ]
			ifFalse: [ (')]}' includes: character)
				ifTrue: [
					depth > 0 ifTrue: [
						spans add: (self spanFrom: index to: index color: (palette at: (depth - 1) \\ palette size + 1)).
						depth := depth - 1 ] ]
				ifFalse: [ character = $'
					ifTrue: [ index := self endOfQuoted: aString from: index terminator: $' ]
					ifFalse: [ character = $"
						ifTrue: [ index := self endOfQuoted: aString from: index terminator: $" ]
						ifFalse: [ character = $$ ifTrue: [ index := index + 1 ] ] ] ] ].
		index := index + 1 ]
]

{ #category : 'requests' }
SwpSession >> endOfQuoted: aString from: openIndex terminator: aCharacter [
	| index |
	index := openIndex + 1.
	[ index <= aString size ] whileTrue: [
		(aString at: index) = aCharacter ifTrue: [
			(index < aString size and: [ (aString at: index + 1) = aCharacter ])
				ifTrue: [ index := index + 2 ]
				ifFalse: [ ^ index ] ]
		ifFalse: [ index := index + 1 ] ].
	^ aString size
]

{ #category : 'requests' }
SwpSession >> parenthesesColors [
	^ { Color blue. Color orange. Color cyan. Color green. Color pink. Color brown. Color purple. Color yellow. Color gray }
		collect: [ :each | self both: (self hexOf: each twiceDarker) ]
]

{ #category : 'requests' }
SwpSession >> boldSpanFrom: aStart to: aStop [
	^ Dictionary new
		at: #start put: aStart;
		at: #stop put: aStop;
		at: #bold put: true;
		yourself
]

{ #category : 'requests' }
SwpSession >> styleNode: aNode into: spans [
	self spanOf: aNode into: spans.
	self commentsOf: aNode into: spans.
	aNode children do: [ :child | self styleNode: child into: spans ]
]

{ #category : 'requests' }
SwpSession >> spanOf: aNode into: spans [
	(aNode isKindOf: OCLiteralValueNode) ifTrue: [
		^ spans add: (self spanFrom: aNode start to: aNode stop color: (self literalColorOf: aNode value)) ].
	aNode isVariable ifTrue: [
		^ (self variableColorOf: aNode name asString)
			ifNotNil: [ :color | spans add: (self spanFrom: aNode start to: aNode stop color: color) ] ].
	aNode isReturn ifTrue: [
		^ spans add: (self spanFrom: aNode start to: aNode start color: self returnColor) ].
	(aNode isKindOf: OCPragmaNode) ifTrue: [
		^ spans add: (self spanFrom: aNode start to: aNode stop color: self pragmaColor) ]
]

{ #category : 'requests' }
SwpSession >> commentsOf: aNode into: spans [
	aNode comments ifNil: [ ^ self ].
	aNode comments do: [ :comment | | interval |
		interval := (comment isKindOf: Interval)
			ifTrue: [ comment ]
			ifFalse: [ comment start to: comment stop ].
		spans add: (self spanFrom: interval first to: interval last color: self commentColor) ]
]

{ #category : 'requests' }
SwpSession >> literalColorOf: aValue [
	aValue isSymbol ifTrue: [ ^ self literalColor ].
	aValue isString ifTrue: [ ^ self literalColor ].
	aValue isNumber ifTrue: [ ^ self scalarColor ].
	aValue isCharacter ifTrue: [ ^ self scalarColor ].
	(aValue isKindOf: Boolean) ifTrue: [ ^ self scalarColor ].
	aValue isNil ifTrue: [ ^ self scalarColor ].
	^ self literalColor
]

{ #category : 'requests' }
SwpSession >> variableColorOf: aName [
	(#('self' 'super' 'thisContext') includes: aName) ifTrue: [ ^ self reservedColor ].
	aName first isUppercase ifTrue: [ ^ self globalColor ].
	^ nil
]

{ #category : 'requests' }
SwpSession >> spanFrom: aStart to: aStop color: aColorPair [
	^ Dictionary new
		at: #start put: aStart;
		at: #stop put: aStop;
		at: #light put: aColorPair first;
		at: #dark put: aColorPair last;
		at: #bold put: false;
		yourself
]

{ #category : 'requests' }
SwpSession >> both: aHex [ ^ { aHex. aHex } ]

{ #category : 'requests' }
SwpSession >> literalColor [ ^ { self hexOf: Color magenta muchDarker. 'E879F9' } ]

{ #category : 'requests' }
SwpSession >> scalarColor [ ^ { self hexOf: Color red muchDarker. 'F87171' } ]

{ #category : 'requests' }
SwpSession >> globalColor [ ^ { self hexOf: Color blue muchDarker. '5C7BD9' } ]

{ #category : 'requests' }
SwpSession >> reservedColor [ ^ { self hexOf: Color cyan muchDarker. '5EEAD4' } ]

{ #category : 'requests' }
SwpSession >> returnColor [ ^ { self hexOf: Color cyan muchDarker. '5EEAD4' } ]

{ #category : 'requests' }
SwpSession >> pragmaColor [ ^ { self hexOf: Color green muchDarker. '4ADE80' } ]

{ #category : 'requests' }
SwpSession >> commentColor [ ^ self both: (self hexOf: Color gray darker) ]

{ #category : 'requests' }
SwpSession >> hexOf: aColor [
	^ (self hexByte: (aColor red * 255) rounded),
	  (self hexByte: (aColor green * 255) rounded),
	  (self hexByte: (aColor blue * 255) rounded)
]

{ #category : 'requests' }
SwpSession >> hexByte: anInteger [
	| hex |
	hex := anInteger printStringBase: 16.
	^ hex size < 2 ifTrue: [ '0', hex ] ifFalse: [ hex ]
]

{ #category : 'requests' }
SwpSession >> undeclaredVariablesOf: aString [
	| variables |
	variables := OrderedCollection new.
	(OCParser parseFaultyExpression: aString) allChildren do: [ :node |
		(self isUndeclaredVariable: node) ifTrue: [
			variables add: (Dictionary new
				at: #name put: node name asString;
				at: #start put: node start;
				at: #stop put: node stop;
				at: #suggestions put: (self suggestionsFor: node name asString) asArray;
				yourself) ] ].
	^ Dictionary new at: #variables put: variables asArray; yourself
]

{ #category : 'requests' }
SwpSession >> isUndeclaredVariable: aNode [
	aNode isVariable ifFalse: [ ^ false ].
	aNode name isEmpty ifTrue: [ ^ false ].
	aNode name first isUppercase ifFalse: [ ^ false ].
	^ (Smalltalk globals includesKey: aNode name asSymbol) not
]

{ #category : 'requests' }
SwpSession >> suggestionsFor: aName [
	| classes |
	classes := Smalltalk globals keys select: [ :each | (Smalltalk globals at: each) isBehavior ].
	^ ((classes asSortedCollection: [ :a :b |
		(self distanceFrom: aName to: a asString) < (self distanceFrom: aName to: b asString) ])
			asArray first: (classes size min: 5)) collect: [ :each | each asString ]
]

{ #category : 'requests' }
SwpSession >> distanceFrom: aString to: bString [
	| row previous |
	row := (0 to: bString size) asArray.
	1 to: aString size do: [ :i |
		previous := row at: 1.
		row at: 1 put: i.
		1 to: bString size do: [ :j | | above cost |
			above := row at: j + 1.
			cost := (aString at: i) = (bString at: j) ifTrue: [ 0 ] ifFalse: [ 1 ].
			row at: j + 1 put: ((((row at: j) + 1) min: (above + 1)) min: (previous + cost)).
			previous := above ] ].
	^ row last
]

{ #category : 'requests' }
SwpSession >> defineClassOf: aDictionary [
	| superclass class |
	superclass := Smalltalk globals at: (aDictionary at: #superclass) asSymbol ifAbsent: [ Object ].
	class := ShiftClassInstaller make: [ :builder |
		builder
			name: (aDictionary at: #name) asSymbol;
			superclass: superclass;
			slots: (self slotsFrom: (aDictionary at: #instanceVariables));
			sharedVariables: (self slotsFrom: (aDictionary at: #classVariables));
			package: (aDictionary at: #package).
		(aDictionary at: #tag) ifNotEmpty: [ :tag | builder tag: tag ] ].
	(aDictionary at: #classInstanceVariables) ifNotEmpty: [ :slots |
		class class instanceVariableNames: slots ].
	^ self describe: class
]

{ #category : 'requests' }
SwpSession >> slotsFrom: aString [
	^ aString substrings collect: [ :each | each asSymbol ]
]

{ #category : 'requests' }
SwpSession >> classReferredToBy: aNode [
	aNode isVariable ifFalse: [ ^ false ].
	^ (Smalltalk globals at: aNode name asSymbol ifAbsent: [ nil ]) isBehavior
]

{ #category : 'requests' }
SwpSession >> viewOf: aDictionary [
	| object |
	object := self objectAt: (aDictionary at: #handle).
	^ (SwpViewCollector viewsFor: object)
		detect: [ :each | each methodSelector = (aDictionary at: #view) asSymbol ]
]

{ #category : 'requests' }
SwpSession >> describe: anObject [
	^ Dictionary new
		at: #handle put: (self handleFor: anObject);
		at: #printString put: anObject printString;
		at: #class put: anObject class name;
		at: #isClass put: anObject isBehavior;
		at: #display put: (self displayOf: anObject);
		yourself
]

{ #category : 'requests' }
SwpSession >> displayOf: anObject [
	| count |
	(anObject isCollection and: [ anObject isString not ]) ifFalse: [ ^ '(', anObject printString, ')' ].
	count := anObject size.
	^ String streamContents: [ :stream |
		stream nextPut: $[; print: count; nextPutAll: ' items] ('.
		(anObject asOrderedCollection first: (count min: 100))
			do: [ :each | stream print: each ] separatedBy: [ stream space ].
		count > 100 ifTrue: [ stream nextPutAll: ' …' ].
		stream nextPut: $) ]
]
