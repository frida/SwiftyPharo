"
A view drawn by the host from a scene it already holds, named here by handle.
The drawing itself stays outside the image: what travels is which scene.
"
Class {
	#name : 'SwpCanvasView',
	#superclass : 'SwpView',
	#instVars : [
		'sceneBlock'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpCanvasView >> declaration [
	^ super declaration
		at: #canvas put: (Dictionary new
			at: 'scene' put: self scene;
			yourself);
		yourself
]

{ #category : 'testing' }
SwpCanvasView >> isEmpty [
	^ self scene isNil
]

{ #category : 'accessing' }
SwpCanvasView >> scene [
	^ sceneBlock ifNil: [ nil ] ifNotNil: [ sceneBlock value ]
]

{ #category : 'building' }
SwpCanvasView >> scene: aBlock [
	sceneBlock := aBlock isBlock ifTrue: [ aBlock ] ifFalse: [ [ aBlock ] ]
]

{ #category : 'accessing' }
SwpCanvasView >> typeName [
	^ 'canvas'
]
