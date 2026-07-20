Class {
	#name : 'SwpTreeView',
	#superclass : 'SwpItemsView',
	#instVars : [
		'childrenBlock'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpTreeView >> children: aBlock [
	childrenBlock := aBlock
]

{ #category : 'accessing' }
SwpTreeView >> childrenOf: anItem [
	^ childrenBlock ifNil: [ #() ] ifNotNil: [ (childrenBlock value: anItem) asOrderedCollection ]
]

{ #category : 'accessing' }
SwpTreeView >> itemAtPath: aCollection [
	^ aCollection inject: nil into: [ :parent :index |
		parent
			ifNil: [ self items at: index ]
			ifNotNil: [ (self childrenOf: parent) at: index ] ]
]

{ #category : 'accessing' }
SwpTreeView >> childTextsAtPath: aCollection [
	| children |
	children := aCollection isEmpty
		ifTrue: [ self items ]
		ifFalse: [ self childrenOf: (self itemAtPath: aCollection) ].
	^ (children collect: [ :each | self textFor: each ]) asArray
]

{ #category : 'accessing' }
SwpTreeView >> typeName [
	^ 'tree'
]
