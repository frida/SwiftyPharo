Class {
	#name : 'SwpColumnedListView',
	#superclass : 'SwpItemsView',
	#instVars : [
		'columns'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpColumnedListView >> column: aTitle text: aBlock [
	self addColumn: aTitle kind: #text block: aBlock
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle text: aBlock width: aWidth [
	(self addColumn: aTitle kind: #text block: aBlock) at: #width put: aWidth
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle item: aBlock [
	self addColumn: aTitle kind: #text block: aBlock
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle evaluated: aBlock [
	self addColumn: aTitle kind: #text block: aBlock
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle icon: aBlock [
	"The block answers a Form, which is how Glamorous Toolkit says a column
	shows a picture."

	self addColumn: aTitle kind: #icon block: aBlock
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle icon: aBlock width: aWidth [
	(self addColumn: aTitle kind: #icon block: aBlock) at: #width put: aWidth
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle [
	"Glamorous Toolkit's object form: a column configured after the fact."

	^ SwpColumn new spec: (self addColumn: aTitle kind: #text block: [ :each | each ])
]

{ #category : 'building' }
SwpColumnedListView >> columnOfType: aColumnClass [
	^ self column: ''
]

{ #category : 'building' }
SwpColumnedListView >> addColumn: aTitle kind: aKind block: aBlock [
	| spec |
	columns ifNil: [ columns := OrderedCollection new ].
	spec := Dictionary new
		        at: #title put: aTitle;
		        at: #kind put: aKind;
		        at: #block put: aBlock;
		        yourself.
	columns add: spec.
	^ spec
]

{ #category : 'accessing' }
SwpColumnedListView >> valueCellsFor: anItem at: anIndex [
	columns ifNil: [ ^ super valueCellsFor: anItem at: anIndex ].
	"JSON has no place for an OrderedCollection."

	^ (columns collect: [ :each | self cellOf: each for: anItem at: anIndex ]) asArray
]

{ #category : 'accessing' }
SwpColumnedListView >> cellOf: aColumn for: anItem at: anIndex [
	| value |
	value := (aColumn at: #block) cull: anItem cull: anIndex.
	(aColumn at: #kind) = #icon ifTrue: [
		^ (value isKindOf: Form)
			  ifTrue: [ SwpViewCollector imageCellOf: value ]
			  ifFalse: [ Dictionary new at: 'text' put: ''; yourself ] ].
	^ Dictionary new
		  at: 'text' put: value asString;
		  yourself
]

{ #category : 'accessing' }
SwpColumnedListView >> columnTitles [
	^ (columns ifNil: [ #() ]) collect: [ :each | each at: #title ]
]

{ #category : 'accessing' }
SwpColumnedListView >> typeName [
	^ 'columnedList'
]
