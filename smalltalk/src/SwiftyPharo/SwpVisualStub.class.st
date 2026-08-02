Class {
	#name : 'SwpVisualStub',
	#superclass : 'Object',
	#classVars : [
		'CapturedLabel'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'class initialization' }
SwpVisualStub class >> initialize [
	self install
]

{ #category : 'class initialization' }
SwpVisualStub class >> install [

	self stubbedGlobals do: [ :name |
		(Smalltalk globals includesKey: name) ifFalse: [
			Smalltalk globals at: name put: self ] ]
]

{ #category : 'class initialization' }
SwpVisualStub class >> stubbedGlobals [
	^ #( BlElement BlTextElement BlLineElement BlPolyline BlDrawnGeometry
	     BlEllipseGeometry BlCircleGeometry BlRectangleGeometry
	     BlRoundedRectangleGeometry BlSquareGeometry BlBorder BlInsets BlPaint
	     BlArrowheadTriangle BlArrowheadSimpleArrow BlArrowheadSimpleLine
	     BlArrowheadCustomShape BrLabel BrText BrEditor BrButton BrFrame
	     BrHorizontalPane BrVerticalPane BrGlamorousLabelAptitude
	     BrGlamorousEditorAptitude BrGlamorousButtonWithIconAptitude
	     BrShadowAptitude BrGlamorousVectorIcons GtPlotterLinearScale
	     GtPlotterDurationScale GtPlotterLogarithmicScale GtPlotterScale )
]

{ #category : 'capturing' }
SwpVisualStub class >> resetCapture [
	CapturedLabel := nil
]

{ #category : 'capturing' }
SwpVisualStub class >> capturedLabel [
	^ CapturedLabel
]

{ #category : 'capturing' }
SwpVisualStub class >> captureText: anObject [
	CapturedLabel := anObject asString
]

{ #category : 'instance creation' }
SwpVisualStub class >> doesNotUnderstand: aMessage [

	^ self new
]

{ #category : 'building' }
SwpVisualStub >> text: anObject [
	self class captureText: anObject
]

{ #category : 'building' }
SwpVisualStub >> label: anObject [
	self class captureText: anObject
]

{ #category : 'building' }
SwpVisualStub >> string: anObject [
	self class captureText: anObject
]

{ #category : 'building' }
SwpVisualStub >> doesNotUnderstand: aMessage [
	^ self
]
