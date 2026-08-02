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

{ #category : 'actions' }
SwpView >> actionUpdateButton [
]

{ #category : 'actions' }
SwpView >> actionUpdateButtonTooltip: aString [
]

{ #category : 'actions' }
SwpView >> actionButtonIcon: anIcon tooltip: aString action: aBlock [
]

{ #category : 'actions' }
SwpView >> actionButtonIcon: anIcon label: aString action: aBlock [
]

{ #category : 'actions' }
SwpView >> actionButtonIcon: anIcon action: aBlock [
]

{ #category : 'actions' }
SwpView >> actionButtonLabel: aString action: aBlock [
]

{ #category : 'actions' }
SwpView >> actionButtonLabel: aString tooltip: aTooltip action: aBlock [
]

{ #category : 'actions' }
SwpView >> actionButtonDo: aBlock [
]

{ #category : 'actions' }
SwpView >> actionDropdownButtonIcon: anIcon tooltip: aString content: aBlock [
]

{ #category : 'actions' }
SwpView >> actionDropdownButtonLabel: aString content: aBlock [
]

{ #category : 'actions' }
SwpView >> actionStencil: aBlock [
]

{ #category : 'actions' }
SwpView >> action: aBlock [
]

{ #category : 'actions' }
SwpView >> addAutoUpdate: aBlock [
]

{ #category : 'actions' }
SwpView >> updateWhen: anAnnouncement in: anAnnouncer [
]

{ #category : 'actions' }
SwpView >> buildContext: aContext [
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
