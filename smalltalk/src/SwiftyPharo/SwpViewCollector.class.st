"
Gathers the views an object declares through <gtView> methods, so objects
written for Glamorous Toolkit describe themselves here unchanged.
"
Class {
	#name : 'SwpViewCollector',
	#superclass : 'Object',
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'collecting' }
SwpViewCollector class >> declarationsFor: anObject [
	^ ((self viewsFor: anObject) collect: [ :each | each declaration ]) asArray
]

{ #category : 'collecting' }
SwpViewCollector class >> viewsFor: anObject [
	| views |
	views := self viewSelectorsFor: anObject.
	views := views collect: [ :selector | self viewOf: anObject bySending: selector ].
	views := views reject: [ :each | each isEmpty ].
	^ views asSortedCollection: [ :a :b | a priority <= b priority ]
]

{ #category : 'collecting' }
SwpViewCollector class >> viewOf: anObject bySending: aSelector [
	| view |
	view := anObject perform: aSelector with: SwpEmptyView new.
	view methodSelector: aSelector.
	^ view
]

{ #category : 'collecting' }
SwpViewCollector class >> viewSelectorsFor: anObject [
	"A subclass overriding a view keeps one entry, the one it inherits last."

	| selectors |
	selectors := OrderedCollection new.
	(Pragma allNamed: #gtView from: anObject class to: ProtoObject) do: [ :each |
		(selectors includes: each methodSelector) ifFalse: [
			selectors add: each methodSelector ] ].
	^ selectors
]
