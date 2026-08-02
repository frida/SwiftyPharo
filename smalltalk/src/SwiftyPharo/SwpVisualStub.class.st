"
Stands in for the Bloc and Brick elements a mondrian stencil builds. It cannot
draw, so it absorbs every message a stencil sends and answers itself, but it
remembers the text a node is labelled with, so the label a painting intended
survives even though the element around it does not. The element class names a
stencil reaches for are bound to this class, so the stencil runs.
"
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
	"Bind the element names a stencil names, so a stencil written for Glamorous
	Toolkit compiles against the stub and runs."

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
	"A class-side constructor -- BlBorder paint:width:, BlInsets all: -- answers a
	stub to keep the stencil flowing."

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
