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
	self column: aTitle showing: #text by: aBlock
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle icon: aBlock [
	"The block answers a Form, which is how Glamorous Toolkit says a column
	shows a picture."

	self column: aTitle showing: #icon by: aBlock
]

{ #category : 'building' }
SwpColumnedListView >> column: aTitle showing: aKind by: aBlock [
	columns ifNil: [ columns := OrderedCollection new ].
	columns add: (Dictionary new
			 at: #title put: aTitle;
			 at: #kind put: aKind;
			 at: #block put: aBlock;
			 yourself)
]

{ #category : 'accessing' }
SwpColumnedListView >> cellsFor: anItem at: anIndex [
	columns ifNil: [ ^ super cellsFor: anItem at: anIndex ].
	^ columns collect: [ :each | self cellOf: each for: anItem ]
]

{ #category : 'accessing' }
SwpColumnedListView >> cellOf: aColumn for: anItem [
	| value |
	value := (aColumn at: #block) value: anItem.
	(aColumn at: #kind) = #icon ifTrue: [ ^ SwpViewCollector imageCellOf: value ].
	^ Dictionary new
		  at: 'text' put: value asString;
		  yourself
]

{ #category : 'accessing' }
SwpColumnedListView >> columnTitles [
	^ (columns ifNil: [ #() ]) collect: [ :each | each at: #title ]
]

{ #category : 'accessing' }
SwpColumnedListView >> declaration [
	^ super declaration
		at: #columns put: self columnTitles asArray;
		yourself
]

{ #category : 'accessing' }
SwpColumnedListView >> typeName [
	^ 'columnedList'
]
