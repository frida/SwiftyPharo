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
SwpMondrian >> addNode: aModel labelBlock: aBlock [
	(indexMap includesKey: aModel) ifTrue: [ ^ self ].
	nodeModels add: aModel.
	nodeLabels add: (self labelFor: aModel with: aBlock).
	indexMap at: aModel put: nodeModels size
]

{ #category : 'building' }
SwpMondrian >> labelFor: aModel with: aBlock [
	| text |
	text := aBlock
		        ifNil: [ self displayFor: aModel ]
		        ifNotNil: [
			        [ (aBlock value: aModel) asString ]
				        on: Error
				        do: [ :error | self displayFor: aModel ] ].
	^ (text size > 100)
		  ifTrue: [ (text first: 99) , (String with: Character value: 8230) ]
		  ifFalse: [ text ]
]

{ #category : 'building' }
SwpMondrian >> displayFor: aModel [
	^ [ aModel displayString ] on: Error do: [ :error | aModel printString ]
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
