"
A view backed by a collection. Items are computed once and then paged, so a
frontend can show the first rows of something large without realising the rest.
"
Class {
	#name : 'SwpItemsView',
	#superclass : 'SwpView',
	#instVars : [
		'itemsBlock',
		'itemTextBlock',
		'sendBlock',
		'computedItems',
		'cellBlocks',
		'columnTitles'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpItemsView >> items [
	^ computedItems ifNil: [
		computedItems := (itemsBlock ifNil: [ [ #() ] ]) value asOrderedCollection ]
]

{ #category : 'building' }
SwpItemsView >> items: aBlock [
	itemsBlock := aBlock
]

{ #category : 'building' }
SwpItemsView >> itemText: aBlock [
	itemTextBlock := aBlock
]

{ #category : 'accessing' }
SwpItemsView >> itemsFrom: anIndex count: aCount [
	| items last |
	items := self items.
	last := (anIndex + aCount - 1) min: items size.
	anIndex > last ifTrue: [ ^ #() ].
	^ ((anIndex to: last) collect: [ :position |
		   self cellsFor: (items at: position) at: position ]) asArray
]

{ #category : 'building' }
SwpItemsView >> send: aBlock [
	sendBlock := aBlock
]

{ #category : 'accessing' }
SwpItemsView >> sentItemAt: anIndex [
	| item |
	item := self items at: anIndex.
	^ sendBlock ifNil: [ item ] ifNotNil: [ sendBlock value: item ]
]

{ #category : 'accessing' }
SwpItemsView >> textFor: anItem [
	^ itemTextBlock
		ifNil: [ anItem printString ]
		ifNotNil: [ (itemTextBlock value: anItem) asString ]
]

{ #category : 'accessing' }
SwpItemsView >> totalItems [
	^ self items size
]

{ #category : 'testing' }
SwpItemsView >> isEmpty [
	^ self totalItems = 0
]

{ #category : 'building' }
SwpItemsView >> cellBlocks: anArray [
	cellBlocks := anArray
]

{ #category : 'accessing' }
SwpItemsView >> columnTitles [
	^ columnTitles ifNil: [ #( 'Item' ) ]
]

{ #category : 'building' }
SwpItemsView >> columnTitles: anArray [
	columnTitles := anArray
]

{ #category : 'converting' }
SwpItemsView >> declaration [
	^ super declaration
		  at: #columns put: ({ 'Index' } , self columnTitles) asArray;
		  yourself
]

{ #category : 'accessing' }
SwpItemsView >> cellsFor: anItem at: anIndex [
	"The framework numbers the rows, the way Glamorous Toolkit prepends an Index
	column no view has to declare; the value cells follow."

	^ { self indexCellFor: anIndex } , (self valueCellsFor: anItem at: anIndex)
]

{ #category : 'accessing' }
SwpItemsView >> valueCellsFor: anItem at: anIndex [
	cellBlocks ifNil: [ ^ { self textCellFor: anItem } ].
	^ (cellBlocks collect: [ :each | each value: anItem value: anIndex ]) asArray
]

{ #category : 'accessing' }
SwpItemsView >> indexCellFor: anIndex [
	^ Dictionary new
		  at: 'text' put: anIndex printString;
		  yourself
]

{ #category : 'accessing' }
SwpItemsView >> textCellFor: anItem [
	^ Dictionary new
		  at: 'text' put: (self textFor: anItem);
		  yourself
]
