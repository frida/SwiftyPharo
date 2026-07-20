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
	columns ifNil: [ columns := OrderedCollection new ].
	columns add: aTitle -> aBlock
]

{ #category : 'accessing' }
SwpColumnedListView >> columnTitles [
	^ (columns ifNil: [ #() ]) collect: [ :each | each key ]
]

{ #category : 'accessing' }
SwpColumnedListView >> declaration [
	^ super declaration
		at: #columns put: self columnTitles asArray;
		yourself
]

{ #category : 'accessing' }
SwpColumnedListView >> textFor: anItem [
	columns ifNil: [ ^ super textFor: anItem ].
	^ (columns collect: [ :each | (each value value: anItem) asString ]) asArray
]

{ #category : 'accessing' }
SwpColumnedListView >> typeName [
	^ 'columnedList'
]
