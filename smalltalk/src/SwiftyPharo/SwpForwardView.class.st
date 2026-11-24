Class {
	#name : 'SwpForwardView',
	#superclass : 'SwpView',
	#instVars : [
		'objectSource',
		'viewSelector',
		'resolved'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpForwardView >> object: aValue [

	objectSource := aValue
]

{ #category : 'building' }
SwpForwardView >> view: aSymbol [
	viewSelector := aSymbol
]

{ #category : 'resolving' }
SwpForwardView >> resolvedView [
	^ resolved ifNil: [ resolved := self resolveView ]
]

{ #category : 'resolving' }
SwpForwardView >> resolveView [
	| target view |
	viewSelector ifNil: [ ^ nil ].
	target := objectSource isBlock
		          ifTrue: [ objectSource value ]
		          ifFalse: [ objectSource ].
	view := SwpViewCollector viewOf: target bySending: viewSelector.
	(view isKindOf: SwpErrorView) ifTrue: [ self error: view text ].
	^ view
]

{ #category : 'testing' }
SwpForwardView >> isEmpty [
	^ self resolvedView isNil or: [ self resolvedView isEmpty ]
]

{ #category : 'accessing' }
SwpForwardView >> typeName [
	^ 'forward'
]

{ #category : 'converting' }
SwpForwardView >> declaration [
	| inner |
	inner := self resolvedView ifNil: [ ^ super declaration ].
	^ inner declaration
		at: #methodSelector put: self methodSelector;
		at: #title put: (title ifNil: [ inner title ]);
		at: #priority put: (self finite: (priority ifNil: [ inner priority ]));
		yourself
]

{ #category : 'accessing' }
SwpForwardView >> totalItems [
	^ self resolvedView totalItems
]

{ #category : 'accessing' }
SwpForwardView >> itemsFrom: anIndex count: aCount [
	^ self resolvedView itemsFrom: anIndex count: aCount
]

{ #category : 'accessing' }
SwpForwardView >> sentItemAt: anIndex [
	^ self resolvedView sentItemAt: anIndex
]

{ #category : 'accessing' }
SwpForwardView >> filter: aString [
	(self resolvedView respondsTo: #filter:) ifTrue: [
		self resolvedView filter: aString ]
]
