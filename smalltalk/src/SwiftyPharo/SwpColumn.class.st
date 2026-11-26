Class {
	#name : 'SwpColumn',
	#superclass : 'Object',
	#instVars : [
		'spec'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpColumn >> spec: aDictionary [
	spec := aDictionary
]

{ #category : 'building' }
SwpColumn >> title: aString [
	spec at: #title put: aString
]

{ #category : 'building' }
SwpColumn >> item: aBlock [
	spec at: #block put: aBlock
]

{ #category : 'building' }
SwpColumn >> text: aBlock [
	self item: aBlock
]

{ #category : 'building' }
SwpColumn >> evaluate: aBlock [
	self item: aBlock
]

{ #category : 'building' }
SwpColumn >> icon: aBlock [
	spec at: #kind put: #icon.
	self item: aBlock
]

{ #category : 'building' }
SwpColumn >> width: aNumber [
	self noWidth.
	spec at: #width put: aNumber
]

{ #category : 'building' }
SwpColumn >> weight: aNumber [
	self noWidth.
	spec at: #weight put: aNumber
]

{ #category : 'building' }
SwpColumn >> fitContent [
	self noWidth.
	spec at: #fitContent put: true
]

{ #category : 'building' }
SwpColumn >> noWidth [
	#( #width #weight #fitContent ) do: [ :each | spec removeKey: each ifAbsent: [ nil ] ]
]

{ #category : 'building' }
SwpColumn >> minimumCharacters: anInteger [
	spec at: #minimumCharacters put: anInteger
]

{ #category : 'building' }
SwpColumn >> priority: aNumber [
	spec at: #priority put: aNumber
]

{ #category : 'building' }
SwpColumn >> background: aBlock [
]

{ #category : 'building' }
SwpColumn >> titleStencil: aBlock [
]
