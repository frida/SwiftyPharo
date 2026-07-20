"
A view an object declares about itself, gathered from its <gtView> methods.
"
Class {
	#name : 'SwpView',
	#superclass : 'Object',
	#instVars : [
		'title',
		'priority',
		'methodSelector'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'testing' }
SwpView >> isEmpty [
	^ false
]

{ #category : 'accessing' }
SwpView >> methodSelector [
	^ methodSelector
]

{ #category : 'accessing' }
SwpView >> methodSelector: aSymbol [
	methodSelector := aSymbol
]

{ #category : 'accessing' }
SwpView >> priority [
	^ priority ifNil: [ 75 ]
]

{ #category : 'accessing' }
SwpView >> priority: aNumber [
	priority := aNumber
]

{ #category : 'accessing' }
SwpView >> title [
	^ title ifNil: [ '' ]
]

{ #category : 'accessing' }
SwpView >> title: aString [
	title := aString
]

{ #category : 'converting' }
SwpView >> declaration [
	^ Dictionary new
		at: #viewName put: self typeName;
		at: #title put: self title;
		at: #priority put: self priority;
		at: #methodSelector put: self methodSelector;
		yourself
]

{ #category : 'accessing' }
SwpView >> typeName [
	^ self subclassResponsibility
]
