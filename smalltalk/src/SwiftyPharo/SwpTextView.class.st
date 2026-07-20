Class {
	#name : 'SwpTextView',
	#superclass : 'SwpView',
	#instVars : [
		'textBlock'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpTextView >> declaration [
	^ super declaration
		at: #text put: self text;
		yourself
]

{ #category : 'accessing' }
SwpTextView >> text [
	^ textBlock ifNil: [ '' ] ifNotNil: [ textBlock value asString ]
]

{ #category : 'building' }
SwpTextView >> text: aBlock [
	textBlock := aBlock isBlock ifTrue: [ aBlock ] ifFalse: [ [ aBlock ] ]
]

{ #category : 'accessing' }
SwpTextView >> typeName [
	^ 'text'
]
