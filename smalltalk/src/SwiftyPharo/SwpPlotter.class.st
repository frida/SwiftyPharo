Class {
	#name : 'SwpPlotter',
	#superclass : 'Object',
	#instVars : [
		'plots'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'initialization' }
SwpPlotter >> initialize [
	super initialize.
	plots := OrderedCollection new
]

{ #category : 'building' }
SwpPlotter >> horizontalBarChart [
	| chart |
	chart := SwpBarChart new.
	plots add: chart.
	^ chart
]

{ #category : 'building' }
SwpPlotter >> verticalBarChart [
	| chart |
	chart := SwpVerticalBarChart new.
	plots add: chart.
	^ chart
]

{ #category : 'building' }
SwpPlotter >> addPlot: aChart [
	plots add: aChart
]

{ #category : 'building' }
SwpPlotter >> asElement [
	plots size = 1 ifTrue: [ ^ plots first ].
	plots isEmpty ifTrue: [ ^ nil ].
	^ SwpCompositeChart new
		  addAll: plots;
		  yourself
]

{ #category : 'building' }
SwpPlotter >> create [
	^ self asElement
]

{ #category : 'building' }
SwpPlotter >> doesNotUnderstand: aMessage [
	^ self
]
