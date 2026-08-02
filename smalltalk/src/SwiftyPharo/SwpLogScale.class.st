"
Stands in for GtPlotterLogarithmicScale. It draws nothing, but a chart asks its
class whether an axis is logarithmic, so a native frontend can match it.
"
Class {
	#name : 'SwpLogScale',
	#superclass : 'Object',
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpLogScale >> doesNotUnderstand: aMessage [
	^ self
]
