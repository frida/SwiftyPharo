"
Records a GtPlotter bar chart as plain structure a native frontend can draw: a
bar per element, each with a label and a value. It stands in for
GtPlotterHorizontalBarChart, so chart code written for Glamorous Toolkit runs
against it unchanged; the value comes from the chart's data block, the label
from the data group, and the Bloc bars it would draw are ignored.
"
Class {
	#name : 'SwpChart',
	#superclass : 'Object',
	#instVars : [
		'dataGroup',
		'widthData',
		'heightData'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'class initialization' }
SwpChart class >> initialize [
	self bindings keysAndValuesDo: [ :name :aClass |
		(Smalltalk globals includesKey: name) ifFalse: [
			Smalltalk globals at: name put: aClass ] ]
]

{ #category : 'class initialization' }
SwpChart class >> bindings [
	^ Dictionary new
		  at: #GtPlotter put: SwpPlotter;
		  at: #GtPlotterHorizontalBarChart put: SwpChart;
		  at: #GtPlotterVerticalBarChart put: SwpChartVertical;
		  at: #GtPlotterDataGroup put: SwpDataGroup;
		  yourself
]

{ #category : 'views' }
SwpChart >> gtChartFor: aView [
	<gtView>
	^ aView explicit
		  title: 'Chart';
		  stencil: [ self ]
]

{ #category : 'building' }
SwpChart >> with: aDataGroup [
	dataGroup := aDataGroup
]

{ #category : 'building' }
SwpChart >> barWidthData: aBlock [
	widthData := aBlock
]

{ #category : 'building' }
SwpChart >> barHeightData: aBlock [
	heightData := aBlock
]

{ #category : 'building' }
SwpChart >> asElement [
	^ self
]

{ #category : 'building' }
SwpChart >> create [
	^ self
]

{ #category : 'building' }
SwpChart >> doesNotUnderstand: aMessage [
	"A chart's scales, ticks, gaps, and Bloc bar shapes have nowhere to draw."

	^ self
]

{ #category : 'accessing' }
SwpChart >> orientation [
	^ 'horizontal'
]

{ #category : 'accessing' }
SwpChart >> models [
	^ dataGroup ifNil: [ #() ] ifNotNil: [ dataGroup values ]
]

{ #category : 'accessing' }
SwpChart >> modelAt: anIndex [
	^ self models at: anIndex
]

{ #category : 'converting' }
SwpChart >> bars [
	| valueBlock |
	valueBlock := self valueBlock.
	^ self models collect: [ :each |
		  Dictionary new
			  at: #label put: (dataGroup labelFor: each) asString;
			  at: #value
			  put: (valueBlock
					   ifNil: [ 0 ]
					   ifNotNil: [ self numberFrom: (valueBlock value: each) ]);
			  yourself ]
]

{ #category : 'converting' }
SwpChart >> valueBlock [
	^ self orientation = 'horizontal'
		  ifTrue: [ widthData ifNil: [ heightData ] ]
		  ifFalse: [ heightData ifNil: [ widthData ] ]
]

{ #category : 'converting' }
SwpChart >> numberFrom: aValue [
	aValue isNumber ifTrue: [ ^ aValue asFloat ].
	^ [ aValue asSeconds asFloat ]
		  on: Error
		  do: [ :error | [ aValue asFloat ] on: Error do: [ :inner | 0.0 ] ]
]

{ #category : 'converting' }
SwpChart >> chartDeclaration [
	^ Dictionary new
		  at: #orientation put: self orientation;
		  at: #bars put: self bars asArray;
		  yourself
]
