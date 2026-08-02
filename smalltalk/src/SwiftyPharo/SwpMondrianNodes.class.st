Class {
	#name : 'SwpMondrianNodes',
	#superclass : 'Object',
	#instVars : [
		'mondrian',
		'labelBlock',
		'stencilBlock'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpMondrianNodes >> mondrian: aMondrian [
	mondrian := aMondrian
]

{ #category : 'building' }
SwpMondrianNodes >> with: aCollection [
	aCollection do: [ :model |
		mondrian addNode: model labelBlock: labelBlock stencil: stencilBlock ]
]

{ #category : 'building' }
SwpMondrianNodes >> with: aCollection forEach: aBlock [
	self with: aCollection.
	mondrian forEach: aBlock
]

{ #category : 'building' }
SwpMondrianNodes >> labelled: aBlock [
	labelBlock := aBlock
]

{ #category : 'building' }
SwpMondrianNodes >> shape: aBlock [

	stencilBlock := aBlock
]

{ #category : 'building' }
SwpMondrianNodes >> stencil: aBlock [
	stencilBlock := aBlock
]

{ #category : 'building' }
SwpMondrianNodes >> ellipse: aBlock [
]

{ #category : 'building' }
SwpMondrianNodes >> umlClassShapeWithName: aBlock [
]

{ #category : 'building' }
SwpMondrianNodes >> umlClassShapeWithName: aBlock andTextAttributes: anotherBlock [
]

{ #category : 'building' }
SwpMondrianNodes >> forEach: aBlock [
	mondrian forEach: aBlock
]

{ #category : 'building' }
SwpMondrianNodes >> forEach: aBlock in: aSymbol [
	mondrian forEach: aBlock
]
