Class {
	#name : 'SwpXYChart',
	#superclass : 'SwpChart',
	#instVars : [
		'dataGroup',
		'xData',
		'yData',
		'xScale',
		'yScale',
		'titleX',
		'titleY'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpXYChart >> with: aDataGroup [
	dataGroup := aDataGroup
]

{ #category : 'building' }
SwpXYChart >> valueX: aBlock [
	xData := aBlock
]

{ #category : 'building' }
SwpXYChart >> valueY: aBlock [
	yData := aBlock
]

{ #category : 'building' }
SwpXYChart >> scaleX: aScale [
	xScale := aScale
]

{ #category : 'building' }
SwpXYChart >> scaleY: aScale [
	yScale := aScale
]

{ #category : 'building' }
SwpXYChart >> titleX: aString [
	titleX := aString
]

{ #category : 'building' }
SwpXYChart >> titleY: aString [
	titleY := aString
]

{ #category : 'accessing' }
SwpXYChart >> titleX [
	^ titleX ifNil: [ '' ]
]

{ #category : 'accessing' }
SwpXYChart >> titleY [
	^ titleY ifNil: [ '' ]
]

{ #category : 'accessing' }
SwpXYChart >> kind [
	^ self subclassResponsibility
]

{ #category : 'accessing' }
SwpXYChart >> models [
	^ dataGroup ifNil: [ #(  ) ] ifNotNil: [ dataGroup values ]
]

{ #category : 'converting' }
SwpXYChart >> scaleXKind [
	^ self kindOfScale: xScale
]

{ #category : 'converting' }
SwpXYChart >> scaleYKind [
	^ self kindOfScale: yScale
]

{ #category : 'converting' }
SwpXYChart >> series [
	^ {
		  (Dictionary new
			   at: #kind put: self kind;
			   at: #orientation put: 'horizontal';
			   at: #points
			   put: (self models collect: [ :model |
					    self
						    pointLabel: (dataGroup labelFor: model)
						    x: (self coordinate: xData of: model)
						    y: (self coordinate: yData of: model) ]) asArray;
			   yourself) }
]

{ #category : 'converting' }
SwpXYChart >> coordinate: aBlock of: aModel [
	^ aBlock ifNil: [ 0.0 ] ifNotNil: [ self numberFrom: (aBlock value: aModel) ]
]
