"
Serves one embedding host. Results stay alive here, keyed by handle, so the host
can walk an object's views long after the expression that produced it returned.
"
Class {
	#name : 'SwpSession',
	#superclass : 'Object',
	#instVars : [
		'objectsByHandle',
		'nextHandle'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'initialization' }
SwpSession >> initialize [
	super initialize.
	objectsByHandle := Dictionary new.
	nextHandle := 0
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
			Dictionary new
				at: #error put: e class name;
				at: #message put: (e messageText ifNil: [ '' ]);
				yourself ])
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
	^ self error: 'unknown op: ', operation
]

{ #category : 'requests' }
SwpSession >> evaluate: aString [
	^ self describe: (Smalltalk compiler evaluate: aString)
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
	| cursor context |
	cursor := SwpCompletionCursor
		source: (aDictionary at: #source)
		position: (aDictionary at: #position).
	context := CoCompletionContext
		engine: cursor
		class: Object
		source: (aDictionary at: #source)
		position: (aDictionary at: #position).
	^ Dictionary new
		at: #tokenStart put: cursor completionTokenStart;
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
		yourself
]
