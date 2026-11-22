Class {
	#name : 'SwpExplicitView',
	#superclass : 'SwpView',
	#instVars : [
		'stencilBlock',
		'chart'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpExplicitView >> stencil: aBlock [
	stencilBlock := aBlock
]

{ #category : 'accessing' }
SwpExplicitView >> chart [
	^ chart ifNil: [ chart := self runStencil ]
]

{ #category : 'accessing' }
SwpExplicitView >> runStencil [
	| result |
	stencilBlock ifNil: [ self error: 'the view was given no stencil' ].
	result := stencilBlock valueWithEnoughArguments: #().
	(result isKindOf: SwpChart) ifFalse: [
		self error: 'the stencil answered ' , result printString , ', which is not a chart' ].
	^ result
]

{ #category : 'testing' }
SwpExplicitView >> isEmpty [
	^ self chart isEmpty
]

{ #category : 'accessing' }
SwpExplicitView >> typeName [
	^ 'chart'
]

{ #category : 'accessing' }
SwpExplicitView >> sentItemAt: anIndex [
	^ self chart modelAt: anIndex
]

{ #category : 'converting' }
SwpExplicitView >> declaration [
	^ super declaration
		  at: #chart put: self chart chartDeclaration;
		  yourself
]
