"
Records a mondrian painting as plain structure a native frontend can draw: the
node models and their labels, the directed edges between them by index, and the
chosen layout. It stands in for GtMondrian, so painting code written for
Glamorous Toolkit runs against it unchanged; the Bloc shapes it would draw are
ignored, since the frontend draws the nodes itself.
"
Class {
	#name : 'SwpMondrian',
	#superclass : 'Object',
	#instVars : [
		'nodeModels',
		'nodeLabels',
		'indexMap',
		'edgePairs',
		'layoutName'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'class initialization' }
SwpMondrian class >> initialize [
	"Offer the builder under a short name, so a playground paints a graph the
	way Glamorous Toolkit reaches for GtMondrian."

	(Smalltalk globals includesKey: #Mondrian) ifFalse: [
		Smalltalk globals at: #Mondrian put: self ]
]

{ #category : 'views' }
SwpMondrian >> gtGraphFor: aView [
	<gtView>
	^ aView mondrian
		  title: 'Graph';
		  capturedMondrian: self
]

{ #category : 'initialization' }
SwpMondrian >> initialize [
	super initialize.
	nodeModels := OrderedCollection new.
	nodeLabels := OrderedCollection new.
	indexMap := IdentityDictionary new.
	edgePairs := OrderedCollection new.
	layoutName := 'grid'
]

{ #category : 'painting' }
SwpMondrian >> nodes [
	^ SwpMondrianNodes new mondrian: self
]

{ #category : 'painting' }
SwpMondrian >> edges [
	^ SwpMondrianEdges new mondrian: self
]

{ #category : 'painting' }
SwpMondrian >> layout [
	^ SwpMondrianLayout new mondrian: self
]

{ #category : 'building' }
SwpMondrian >> addNode: aModel labelBlock: aLabelBlock stencil: aStencilBlock [
	(indexMap includesKey: aModel) ifTrue: [ ^ self ].
	nodeModels size >= self nodeLimit ifTrue: [ ^ self ].
	nodeModels add: aModel.
	nodeLabels add: (self labelFor: aModel with: aLabelBlock stencil: aStencilBlock).
	indexMap at: aModel put: nodeModels size
]

{ #category : 'building' }
SwpMondrian >> nodeLimit [
	^ 2000
]

{ #category : 'building' }
SwpMondrian >> labelFor: aModel with: aLabelBlock stencil: aStencilBlock [
	aLabelBlock ifNotNil: [
		^ self truncate:
			  ([ (aLabelBlock value: aModel) asString ]
				   on: Error
				   do: [ :error | self displayFor: aModel ]) ].
	aStencilBlock ifNotNil: [
		SwpVisualStub resetCapture.
		[ aStencilBlock value: aModel ] on: Error do: [ :error | nil ].
		SwpVisualStub capturedLabel ifNotNil: [ :text |
			^ self truncate: text ] ].
	^ self truncate: (self displayFor: aModel)
]

{ #category : 'building' }
SwpMondrian >> truncate: aString [
	^ aString size > 100
		  ifTrue: [ (aString first: 99) , (String with: Character value: 8230) ]
		  ifFalse: [ aString ]
]

{ #category : 'building' }
SwpMondrian >> displayFor: aModel [
	^ [ aModel displayString ] on: Error do: [ :error | aModel printString ]
]

{ #category : 'building' }
SwpMondrian >> forEach: aBlock [
	"Draw each node's own sub-graph flat, joining a node to the children its
	painting adds so the nesting reads as edges."

	nodeModels copy doWithIndex: [ :parent :ignored |
		| firstChild |
		firstChild := nodeModels size + 1.
		aBlock value: parent.
		firstChild to: nodeModels size do: [ :child |
			edgePairs add: (indexMap at: parent) -> child ] ]
]

{ #category : 'building' }
SwpMondrian >> layoutName: aString [
	layoutName := aString
]

{ #category : 'edges' }
SwpMondrian >> connectFrom: aFrom fromMany: fromMany to: aTo toMany: toMany [
	nodeModels copy doWithIndex: [ :model :ignored |
		| sources targets |
		sources := self resolve: aFrom many: fromMany for: model.
		targets := self resolve: aTo many: toMany for: model.
		sources do: [ :source |
			targets do: [ :target | self addEdgeFrom: source to: target ] ] ]
]

{ #category : 'edges' }
SwpMondrian >> resolve: aResolver many: many for: aModel [
	| value |
	aResolver ifNil: [ ^ { aModel } ].
	value := aResolver isSymbol
		         ifTrue: [ aModel perform: aResolver ]
		         ifFalse: [
			         aResolver isBlock
				         ifTrue: [ aResolver value: aModel ]
				         ifFalse: [ aResolver ] ].
	^ many
		  ifTrue: [ (value isCollection and: [ value isString not ])
				  ifTrue: [ value ]
				  ifFalse: [ { value } ] ]
		  ifFalse: [ { value } ]
]

{ #category : 'edges' }
SwpMondrian >> addEdgeFrom: aFromModel to: aToModel [
	| from to |
	from := indexMap at: aFromModel ifAbsent: [ ^ self ].
	to := indexMap at: aToModel ifAbsent: [ ^ self ].
	edgePairs add: from -> to
]

{ #category : 'accessing' }
SwpMondrian >> nodeModels [
	^ nodeModels
]

{ #category : 'converting' }
SwpMondrian >> graphDeclaration [
	^ Dictionary new
		  at: #layout put: layoutName;
		  at: #nodes
		  put: (nodeLabels
				   collect: [ :label | Dictionary new at: #label put: label; yourself ])
				  asArray;
		  at: #edges
		  put: (edgePairs
				   collect: [ :pair |
					   Dictionary new
						   at: #from put: pair key - 1;
						   at: #to put: pair value - 1;
						   yourself ])
				  asArray;
		  yourself
]
