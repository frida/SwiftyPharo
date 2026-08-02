"
One column of a columned list, configured the way Glamorous Toolkit configures
a GtPhlowColumn: a title and a block that yields each cell. It writes through to
the dictionary the view keeps, so however it is configured the view sees it.
"
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
	spec at: #width put: aNumber
]

{ #category : 'building' }
SwpColumn >> weight: aNumber [
	spec at: #weight put: aNumber
]

{ #category : 'building' }
SwpColumn >> noWidth [
	spec removeKey: #width ifAbsent: [ nil ]
]

{ #category : 'building' }
SwpColumn >> background: aBlock [
	"The shim draws no cell backgrounds."
]

{ #category : 'building' }
SwpColumn >> titleStencil: aBlock [
	"Nor custom header elements."
]
