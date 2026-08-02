"
The node builder a mondrian painting configures, standing in for
GtMondrianNodeBuilder. It takes the collection a graph draws and remembers a
label for each; the Bloc shapes it is handed have nowhere to draw and are
ignored.
"
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
	"A node's Bloc element cannot be drawn, but running it captures the label the
	painting meant the node to carry."

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
