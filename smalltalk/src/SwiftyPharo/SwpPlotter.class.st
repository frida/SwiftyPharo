"
The container a chart is built through, standing in for GtPlotter. It hands out
a bar chart to configure and answers that chart as its element.
"
Class {
	#name : 'SwpPlotter',
	#superclass : 'Object',
	#instVars : [
		'chart'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpPlotter >> horizontalBarChart [
	^ chart := SwpChart new
]

{ #category : 'building' }
SwpPlotter >> verticalBarChart [
	^ chart := SwpChartVertical new
]

{ #category : 'building' }
SwpPlotter >> addPlot: aChart [
	chart := aChart
]

{ #category : 'building' }
SwpPlotter >> asElement [
	^ chart
]

{ #category : 'building' }
SwpPlotter >> create [
	^ chart
]

{ #category : 'building' }
SwpPlotter >> doesNotUnderstand: aMessage [
	^ self
]
