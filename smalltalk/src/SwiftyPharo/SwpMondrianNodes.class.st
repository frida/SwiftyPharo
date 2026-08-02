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
		'labelBlock'
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
	aCollection do: [ :model | mondrian addNode: model labelBlock: labelBlock ]
]

{ #category : 'building' }
SwpMondrianNodes >> with: aCollection forEach: aBlock [
	"Nested sub-graphs are flattened away; the top-level nodes are drawn."

	self with: aCollection
]

{ #category : 'building' }
SwpMondrianNodes >> labelled: aBlock [
	labelBlock := aBlock
]

{ #category : 'building' }
SwpMondrianNodes >> shape: aBlock [
	"A node's Bloc element cannot be drawn here; its label comes from the model."
]

{ #category : 'building' }
SwpMondrianNodes >> stencil: aBlock [
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
]

{ #category : 'building' }
SwpMondrianNodes >> forEach: aBlock in: aSymbol [
]
