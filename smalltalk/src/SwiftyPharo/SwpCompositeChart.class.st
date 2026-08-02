Class {
	#name : 'SwpCompositeChart',
	#superclass : 'SwpChart',
	#instVars : [
		'plots'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'initialization' }
SwpCompositeChart >> initialize [
	super initialize.
	plots := OrderedCollection new
]

{ #category : 'building' }
SwpCompositeChart >> addPlot: aChart [
	plots add: aChart
]

{ #category : 'building' }
SwpCompositeChart >> addAll: aCollection [
	plots addAll: aCollection
]

{ #category : 'accessing' }
SwpCompositeChart >> models [
	^ Array streamContents: [ :stream |
		  plots do: [ :plot | stream nextPutAll: plot models ] ]
]

{ #category : 'converting' }
SwpCompositeChart >> series [
	^ Array streamContents: [ :stream |
		  plots do: [ :plot | stream nextPutAll: plot series ] ]
]

{ #category : 'converting' }
SwpCompositeChart >> titleX [
	^ plots ifEmpty: [ '' ] ifNotEmpty: [ plots first titleX ]
]

{ #category : 'converting' }
SwpCompositeChart >> titleY [
	^ plots ifEmpty: [ '' ] ifNotEmpty: [ plots first titleY ]
]

{ #category : 'converting' }
SwpCompositeChart >> scaleXKind [
	^ plots
		  ifEmpty: [ 'linear' ]
		  ifNotEmpty: [ plots first scaleXKind ]
]

{ #category : 'converting' }
SwpCompositeChart >> scaleYKind [
	^ plots
		  ifEmpty: [ 'linear' ]
		  ifNotEmpty: [ plots first scaleYKind ]
]
