"
The base of the GtPlotter charts a frontend draws natively. A chart answers its
series -- each a run of points with a label and an x and a y -- and the kind of
scale each axis carries, and stands in for the Bloc bars, lines, and dots a
GtPlotter would draw. A point drills into the element behind it.
"
Class {
	#name : 'SwpChart',
	#superclass : 'Object',
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
		  at: #GtPlotterHorizontalBarChart put: SwpBarChart;
		  at: #GtPlotterVerticalBarChart put: SwpVerticalBarChart;
		  at: #GtPlotterLineChart put: SwpLineChart;
		  at: #GtPlotterScatterChart put: SwpScatterChart;
		  at: #GtPlotterCompositeChart put: SwpCompositeChart;
		  at: #GtPlotterDataGroup put: SwpDataGroup;
		  at: #GtPlotterLogarithmicScale put: SwpLogScale;
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
SwpChart >> asElement [
	^ self
]

{ #category : 'building' }
SwpChart >> create [
	^ self
]

{ #category : 'building' }
SwpChart >> doesNotUnderstand: aMessage [
	"A chart's ticks, titles, gaps, and Bloc shapes have nowhere to draw."

	^ self
]

{ #category : 'accessing' }
SwpChart >> models [
	^ #(  )
]

{ #category : 'accessing' }
SwpChart >> modelAt: anIndex [
	^ self models at: anIndex
]

{ #category : 'testing' }
SwpChart >> isEmpty [
	^ self models isEmpty
]

{ #category : 'converting' }
SwpChart >> series [
	^ #(  )
]

{ #category : 'converting' }
SwpChart >> scaleXKind [
	^ 'linear'
]

{ #category : 'converting' }
SwpChart >> scaleYKind [
	^ 'linear'
]

{ #category : 'converting' }
SwpChart >> kindOfScale: aScale [
	^ (aScale isKindOf: SwpLogScale) ifTrue: [ 'log' ] ifFalse: [ 'linear' ]
]

{ #category : 'converting' }
SwpChart >> pointLabel: aLabel x: anX y: aY [
	^ Dictionary new
		  at: #label put: aLabel asString;
		  at: #x put: anX;
		  at: #y put: aY;
		  yourself
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
		  at: #scaleX put: self scaleXKind;
		  at: #scaleY put: self scaleYKind;
		  at: #series put: self series asArray;
		  yourself
]
