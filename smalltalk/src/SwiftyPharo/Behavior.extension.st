Extension { #name : 'Behavior' }

{ #category : '*SwiftyPharo' }
Behavior >> swpMethodsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Methods';
		priority: 1;
		items: [ self swpMethods ];
		column: 'Method' do: [ :column |
			column
				text: [ :each | each selector ];
				priority: 1 ];
		column: 'Side' do: [ :column |
			column
				text: [ :each | each methodClass isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ] ];
				fitContent;
				priority: 3 ];
		column: 'Category' do: [ :column |
			column
				text: [ :each | each protocol name ];
				priority: 2 ]
]

{ #category : '*SwiftyPharo' }
Behavior >> swpMethods [
	^ ((self methods , self class methods)
		asSortedCollection: [ :a :b | a selector <= b selector ]) asArray
]

{ #category : '*SwiftyPharo' }
Behavior >> swpTag [
	| category package |
	category := self category ifNil: [ ^ '' ].
	package := self package name.
	^ category = package
		ifTrue: [ '' ]
		ifFalse: [ category allButFirst: package size + 1 ]
]
