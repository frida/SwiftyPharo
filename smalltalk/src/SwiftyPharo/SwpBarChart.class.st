Class {
	#name : 'SwpBarChart',
	#superclass : 'SwpChart',
	#instVars : [
		'dataGroup',
		'widthData',
		'heightData',
		'widthScale',
		'heightScale'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpBarChart >> with: aDataGroup [
	dataGroup := aDataGroup
]

{ #category : 'building' }
SwpBarChart >> barWidthData: aBlock [
	widthData := aBlock
]

{ #category : 'building' }
SwpBarChart >> barHeightData: aBlock [
	heightData := aBlock
]

{ #category : 'building' }
SwpBarChart >> barWidthScale: aScale [
	widthScale := aScale
]

{ #category : 'building' }
SwpBarChart >> barHeightScale: aScale [
	heightScale := aScale
]

{ #category : 'accessing' }
SwpBarChart >> orientation [
	^ 'horizontal'
]

{ #category : 'accessing' }
SwpBarChart >> valueBlock [
	^ self orientation = 'horizontal'
		  ifTrue: [ widthData ifNil: [ heightData ] ]
		  ifFalse: [ heightData ifNil: [ widthData ] ]
]

{ #category : 'accessing' }
SwpBarChart >> valueScale [
	^ self orientation = 'horizontal'
		  ifTrue: [ widthScale ifNil: [ heightScale ] ]
		  ifFalse: [ heightScale ifNil: [ widthScale ] ]
]

{ #category : 'accessing' }
SwpBarChart >> models [
	^ dataGroup ifNil: [ #(  ) ] ifNotNil: [ dataGroup values ]
]

{ #category : 'converting' }
SwpBarChart >> scaleXKind [
	^ self orientation = 'horizontal'
		  ifTrue: [ self kindOfScale: self valueScale ]
		  ifFalse: [ 'linear' ]
]

{ #category : 'converting' }
SwpBarChart >> scaleYKind [
	^ self orientation = 'vertical'
		  ifTrue: [ self kindOfScale: self valueScale ]
		  ifFalse: [ 'linear' ]
]

{ #category : 'converting' }
SwpBarChart >> series [
	| value |
	value := self valueBlock.
	^ {
		  (Dictionary new
			   at: #kind put: 'bar';
			   at: #orientation put: self orientation;
			   at: #points
			   put: (self models withIndexCollect: [ :model :index |
					    self
						    pointLabel: (dataGroup labelFor: model)
						    x: index asFloat
						    y: (value
								     ifNil: [ 0.0 ]
								     ifNotNil: [ self numberFrom: (value value: model) ]) ]) asArray;
			   yourself) }
]
