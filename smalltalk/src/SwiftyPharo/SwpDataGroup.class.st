"
The data a chart draws, standing in for GtPlotterDataGroup: the collection of
elements and the block that labels each one.
"
Class {
	#name : 'SwpDataGroup',
	#superclass : 'Object',
	#instVars : [
		'values',
		'labelBlock'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpDataGroup >> values: aCollection [
	values := aCollection asOrderedCollection
]

{ #category : 'building' }
SwpDataGroup >> labelled: aBlock [
	labelBlock := aBlock
]

{ #category : 'building' }
SwpDataGroup >> sorted: aBlock [
	values := (self values asSortedCollection: aBlock) asOrderedCollection
]

{ #category : 'building' }
SwpDataGroup >> doesNotUnderstand: aMessage [
	"A group's colours and other trimmings have nowhere to draw."

	^ self
]

{ #category : 'accessing' }
SwpDataGroup >> values [
	^ values ifNil: [ #() ]
]

{ #category : 'accessing' }
SwpDataGroup >> labelFor: anElement [
	^ labelBlock
		  ifNil: [ anElement displayString ]
		  ifNotNil: [ (labelBlock value: anElement) asString ]
]
