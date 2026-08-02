Class {
	#name : 'SwpMondrianLayout',
	#superclass : 'Object',
	#instVars : [
		'mondrian'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpMondrianLayout >> mondrian: aMondrian [
	mondrian := aMondrian
]

{ #category : 'layouts' }
SwpMondrianLayout >> tree [
	mondrian layoutName: 'tree'
]

{ #category : 'layouts' }
SwpMondrianLayout >> dominanceTree [
	mondrian layoutName: 'tree'
]

{ #category : 'layouts' }
SwpMondrianLayout >> sugiyama [
	mondrian layoutName: 'tree'
]

{ #category : 'layouts' }
SwpMondrianLayout >> radialTree [
	mondrian layoutName: 'tree'
]

{ #category : 'layouts' }
SwpMondrianLayout >> horizontalTree [
	mondrian layoutName: 'horizontalTree'
]

{ #category : 'layouts' }
SwpMondrianLayout >> horizontalDominanceTree [
	mondrian layoutName: 'horizontalTree'
]

{ #category : 'layouts' }
SwpMondrianLayout >> grid [
	mondrian layoutName: 'grid'
]

{ #category : 'layouts' }
SwpMondrianLayout >> rectanglePack [
	mondrian layoutName: 'grid'
]

{ #category : 'layouts' }
SwpMondrianLayout >> circle [
	mondrian layoutName: 'circle'
]

{ #category : 'layouts' }
SwpMondrianLayout >> horizontal [
	mondrian layoutName: 'horizontalLine'
]

{ #category : 'layouts' }
SwpMondrianLayout >> vertical [
	mondrian layoutName: 'verticalLine'
]

{ #category : 'layouts' }
SwpMondrianLayout >> force [
	mondrian layoutName: 'force'
]

{ #category : 'tuning' }
SwpMondrianLayout >> nodeDistance: aNumber [
]

{ #category : 'tuning' }
SwpMondrianLayout >> levelDistance: aNumber [
]

{ #category : 'tuning' }
SwpMondrianLayout >> custom: aLayout [
]

{ #category : 'tuning' }
SwpMondrianLayout >> explicit: aLayout [
]
