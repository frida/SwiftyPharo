"
An explicit view builds a Bloc element by hand, which has nowhere to draw here.
When that element is a GtPlotter chart, though, the view shows it as a native
chart; otherwise the view has nothing to show and drops out.
"
Class {
	#name : 'SwpExplicitView',
	#superclass : 'SwpView',
	#instVars : [
		'stencilBlock',
		'chart',
		'captured'
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
	captured ifNil: [
		chart := self runStencil.
		captured := true ].
	^ chart
]

{ #category : 'accessing' }
SwpExplicitView >> runStencil [
	| result |
	stencilBlock ifNil: [ ^ nil ].
	result := [ stencilBlock valueWithEnoughArguments: #() ]
		          on: Error
		          do: [ :error | nil ].
	^ (result isKindOf: SwpChart) ifTrue: [ result ] ifFalse: [ nil ]
]

{ #category : 'testing' }
SwpExplicitView >> isEmpty [
	^ self chart isNil or: [ self chart isEmpty ]
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
