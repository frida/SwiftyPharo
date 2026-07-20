"
Gathers the views an object declares, both the <gtView> methods objects written
for Glamorous Toolkit carry and the <inspectorPresentationOrder:title:> methods
stock Pharo describes itself with. Almost nothing outside GT declares the
former, so the latter is what an ordinary object shows.
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
	views := (self gtViewsFor: anObject) , (self inspectorViewsFor: anObject).
	views := views reject: [ :each | each isEmpty ].
	^ views asSortedCollection: [ :a :b | a priority <= b priority ]
]

{ #category : 'collecting' }
SwpViewCollector class >> gtViewsFor: anObject [
	^ (self gtViewSelectorsFor: anObject) collect: [ :selector |
		  self viewOf: anObject bySending: selector ]
]

{ #category : 'collecting' }
SwpViewCollector class >> gtViewSelectorsFor: anObject [
	"A subclass overriding a view keeps one entry, the one it inherits last."

	| selectors |
	selectors := OrderedCollection new.
	(Pragma allNamed: #gtView from: anObject class to: ProtoObject) do: [ :each |
		(selectors includes: each methodSelector) ifFalse: [
			selectors add: each methodSelector ] ].
	^ selectors
]

{ #category : 'collecting' }
SwpViewCollector class >> viewOf: anObject bySending: aSelector [
	| view |
	view := anObject perform: aSelector with: SwpEmptyView new.
	view methodSelector: aSelector.
	^ view
]

{ #category : 'collecting' }
SwpViewCollector class >> inspectorViewsFor: anObject [
	| views |
	views := OrderedCollection new.
	(self inspectorPragmasFor: anObject) do: [ :pragma |
		(self viewOf: anObject byBuilding: pragma) ifNotNil: [ :view |
			views add: view ] ].
	^ views
]

{ #category : 'collecting' }
SwpViewCollector class >> inspectorPragmasFor: anObject [
	"A subclass overriding a view keeps one entry, the one it inherits last."

	| pragmas selectors |
	pragmas := OrderedCollection new.
	selectors := Set new.
	(Pragma
		 allNamed: #inspectorPresentationOrder:title:
		 from: anObject class
		 to: ProtoObject) do: [ :each |
		(selectors includes: each methodSelector) ifFalse: [
			selectors add: each methodSelector.
			pragmas add: each ] ].
	^ pragmas
]

{ #category : 'collecting' }
SwpViewCollector class >> viewOf: anObject byBuilding: aPragma [
	"These run whatever the image supplies, and a view that cannot build itself
	should cost only itself."

	| presenter view |
	presenter := [
	             anObject
		             perform: aPragma methodSelector
		             with: self presenterBuilder ]
		             on: Error
		             do: [ :error | nil ].
	presenter ifNil: [ ^ nil ].

	view := self viewOfPresenter: presenter.
	view ifNil: [ ^ nil ].

	view
		title: aPragma arguments second;
		priority: aPragma arguments first;
		methodSelector: aPragma methodSelector.
	^ view
]

{ #category : 'collecting' }
SwpViewCollector class >> viewOfPresenter: aPresenter [
	"Asked by what a presenter can answer rather than what it is, since Spec
	spreads rows across list, table and tree presenters that share no
	superclass worth naming here."

	(aPresenter respondsTo: #items) ifTrue: [
		^ self listViewOfItems: aPresenter items ].
	(aPresenter respondsTo: #roots) ifTrue: [
		^ self listViewOfItems: aPresenter roots ].
	(aPresenter respondsTo: #text) ifTrue: [
		^ SwpTextView new
			  text: aPresenter text asString;
			  yourself ].
	^ self viewOfComposedPresenter: aPresenter
]

{ #category : 'collecting' }
SwpViewCollector class >> viewOfComposedPresenter: aPresenter [
	"The inspection presenters wrap their rows in a presenter that only lays
	its parts out."

	(aPresenter respondsTo: #presenters) ifFalse: [ ^ nil ].
	aPresenter presenters do: [ :each |
		(self viewOfPresenter: each) ifNotNil: [ :view | ^ view ] ].
	^ nil
]

{ #category : 'collecting' }
SwpViewCollector class >> listViewOfItems: aCollection [
	| items |
	items := aCollection asOrderedCollection.
	^ SwpListView new
		  items: [ items ];
		  itemText: [ :each | each printString ];
		  send: [ :each | each ];
		  yourself
]

{ #category : 'collecting' }
SwpViewCollector class >> presenterBuilder [
	^ SpPresenterBuilder newApplication: SpApplication new
]
