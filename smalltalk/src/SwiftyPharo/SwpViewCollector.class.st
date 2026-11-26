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
	"A view whose declaration cannot build itself -- a block that raises, a
	message the shim does not answer -- costs only itself, not the object's
	other views."

	^ (self viewsFor: anObject) collect: [ :each | self declarationOf: each ] as: Array
]

{ #category : 'collecting' }
SwpViewCollector class >> viewsFor: anObject [
	"A view the method described but left without content still earns its tab,
	the way Glamorous Toolkit shows an empty list; only one that described
	nothing -- leaving the builder untouched -- is dropped."

	| views |
	views := (self gtViewsFor: anObject) , (self inspectorViewsFor: anObject).
	views := views reject: [ :each | each isKindOf: SwpEmptyView ].
	^ views asSortedCollection: #priority ascending , #methodSelector ascending
]

{ #category : 'collecting' }
SwpViewCollector class >> declarationOf: aView [
	^ [ aView declaration ]
		  on: Error
		  do: [ :error | (SwpErrorView replacing: aView saying: 'raised ' , error description) declaration ]
]

{ #category : 'collecting' }
SwpViewCollector class >> gtViewsFor: anObject [
	^ (self gtViewSelectorsFor: anObject) collect: [ :selector | self viewOf: anObject bySending: selector ]
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
	view := [ anObject perform: aSelector with: SwpEmptyView new ]
		        on: Error
		        do: [ :error | ^ SwpErrorView of: aSelector saying: 'raised ' , error description ].
	(view isKindOf: SwpView) ifFalse: [
		^ SwpErrorView of: aSelector saying: 'answered ' , view printString , ', which is not a view' ].
	(view priority isNumber and: [ view priority isNaN not ]) ifFalse: [
		^ SwpErrorView of: aSelector saying: 'gave the priority ' , view priority printString , ', which is not a number' ].
	^ view
		  methodSelector: aSelector;
		  yourself
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
		             do: [ :error |
			             ^ (SwpErrorView of: aPragma methodSelector saying: 'raised ' , error description)
				               title: aPragma arguments second , ' (Error)';
				               priority: aPragma arguments first;
				               yourself ].

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
		^ self listViewOf: aPresenter items in: aPresenter ].
	(aPresenter respondsTo: #roots) ifTrue: [
		^ self listViewOf: aPresenter roots in: aPresenter ].
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
SwpViewCollector class >> listViewOf: aCollection in: aPresenter [
	| items view columns |
	items := aCollection asOrderedCollection.
	view := SwpListView new
		        items: [ items ];
		        itemText: [ :each | self textForRow: each ];
		        send: [ :each | self valueOfRow: each ];
		        yourself.

	columns := (aPresenter respondsTo: #columns)
		           ifTrue: [ aPresenter columns ]
		           ifFalse: [ #() ].
	columns := columns reject: [ :each | each isKindOf: SpIndexTableColumn ].
	columns ifNotEmpty: [
		view cellBlocks: (columns collect: [ :each | self cellBlockOf: each ]).
		view columnDeclarations: (columns collect: [ :each | self declarationOfColumn: each ]) ].
	^ view
]

{ #category : 'collecting' }
SwpViewCollector class >> declarationOfColumn: aColumn [
	| declaration |
	declaration := Dictionary new
		               at: #title put: (self titleOf: aColumn);
		               yourself.
	(aColumn width notNil or: [ aColumn isExpandable not ]) ifTrue: [
		declaration at: #fitContent put: true ].
	^ declaration
]

{ #category : 'collecting' }
SwpViewCollector class >> titleOf: aColumn [
	^ (aColumn respondsTo: #title)
		  ifTrue: [ aColumn title ifNil: [ 'Item' ] ]
		  ifFalse: [ 'Item' ]
]

{ #category : 'collecting' }
SwpViewCollector class >> cellBlockOf: aColumn [
	"An image column is how both Pharo and Glamorous Toolkit say a cell shows
	a picture rather than words."

	(aColumn isKindOf: SpImageTableColumn) ifTrue: [
		^ [ :item :index | self imageCellOf: (aColumn evaluateObject: item) ] ].
	^ [ :item :index |
	  Dictionary new
		  at: 'text' put: (self textOf: aColumn for: item);
		  yourself ]
]

{ #category : 'collecting' }
SwpViewCollector class >> textOf: aColumn for: anItem [
	aColumn isComposite ifFalse: [ ^ (aColumn evaluateObject: anItem) asString ].
	^ ' ' join: ((aColumn columns reject: [ :each | each isKindOf: SpImageTableColumn ]) collect: [ :each |
			   self textOf: each for: anItem ])
]

{ #category : 'collecting' }
SwpViewCollector class >> imageCellOf: aForm [
	| png |
	png := ByteArray streamContents: [ :stream |
		       PNGReadWriter putForm: aForm onStream: stream ].
	^ Dictionary new
		  at: 'png' put: png base64Encoded;
		  yourself
]

{ #category : 'collecting' }
SwpViewCollector class >> textForRow: anItem [
	"The inspection presenters hand out nodes that name a slot and hold its
	value, rather than the value itself."

	((anItem respondsTo: #label) and: [ anItem respondsTo: #value ]) ifTrue: [
		^ anItem label asString , ': ' , anItem value printString ].
	^ anItem printString
]

{ #category : 'collecting' }
SwpViewCollector class >> valueOfRow: anItem [
	^ (anItem respondsTo: #rawValue)
		  ifTrue: [ anItem rawValue ]
		  ifFalse: [ anItem ]
]

{ #category : 'collecting' }
SwpViewCollector class >> presenterBuilder [
	^ SpPresenterBuilder newApplication: SpApplication new
]
