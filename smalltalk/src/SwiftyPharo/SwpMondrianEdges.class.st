Class {
	#name : 'SwpMondrianEdges',
	#superclass : 'Object',
	#instVars : [
		'mondrian'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpMondrianEdges >> mondrian: aMondrian [
	mondrian := aMondrian
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectFrom: aResolver [
	mondrian connectFrom: aResolver fromMany: false to: nil toMany: false
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectFromAll: aResolver [
	mondrian connectFrom: aResolver fromMany: true to: nil toMany: false
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectTo: aResolver [
	mondrian connectFrom: nil fromMany: false to: aResolver toMany: false
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectToAll: aResolver [
	mondrian connectFrom: nil fromMany: false to: aResolver toMany: true
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectFrom: aFrom to: aTo [
	mondrian connectFrom: aFrom fromMany: false to: aTo toMany: false
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectFrom: aFrom toAll: aTo [
	mondrian connectFrom: aFrom fromMany: false to: aTo toMany: true
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectFromAll: aFrom to: aTo [
	mondrian connectFrom: aFrom fromMany: true to: aTo toMany: false
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectFromAll: aFrom toAll: aTo [
	mondrian connectFrom: aFrom fromMany: true to: aTo toMany: true
]

{ #category : 'connecting' }
SwpMondrianEdges >> connectAssociations: aCollection [
	aCollection do: [ :each | mondrian addEdgeFrom: each key to: each value ]
]

{ #category : 'connecting' }
SwpMondrianEdges >> connect: aShape from: aResolver [
	self connectFrom: aResolver
]

{ #category : 'connecting' }
SwpMondrianEdges >> connect: aShape to: aResolver [
	self connectTo: aResolver
]

{ #category : 'connecting' }
SwpMondrianEdges >> connect: aShape toAll: aResolver [
	self connectToAll: aResolver
]

{ #category : 'connecting' }
SwpMondrianEdges >> connect: aShape from: aFrom to: aTo [
	self connectFrom: aFrom to: aTo
]

{ #category : 'shape' }
SwpMondrianEdges >> stencil: aBlock [
]

{ #category : 'shape' }
SwpMondrianEdges >> shape: aBlock [
]

{ #category : 'shape' }
SwpMondrianEdges >> fromRightCenter [
]

{ #category : 'shape' }
SwpMondrianEdges >> toLeftCenter [
]

{ #category : 'shape' }
SwpMondrianEdges >> fromLeftCenter [
]

{ #category : 'shape' }
SwpMondrianEdges >> toRightCenter [
]

{ #category : 'shape' }
SwpMondrianEdges >> fromCenterTop [
]

{ #category : 'shape' }
SwpMondrianEdges >> fromCenterBottom [
]

{ #category : 'shape' }
SwpMondrianEdges >> toCenterTop [
]

{ #category : 'shape' }
SwpMondrianEdges >> toCenterBottom [
]

{ #category : 'shape' }
SwpMondrianEdges >> fromAnchor: anAnchor [
]

{ #category : 'shape' }
SwpMondrianEdges >> toAnchor: anAnchor [
]

{ #category : 'shape' }
SwpMondrianEdges >> passive [
]

{ #category : 'shape' }
SwpMondrianEdges >> areEdgesPassive: aBoolean [
]
