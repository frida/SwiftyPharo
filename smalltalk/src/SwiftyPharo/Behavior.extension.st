Extension { #name : 'Behavior' }

{ #category : '*SwiftyPharo' }
Behavior >> swpMethodsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Methods';
		priority: 1;
		items: [ self swpMethods ];
		column: 'Method' text: [ :each | each selector ];
		column: 'Side' text: [ :each | each methodClass isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ] ];
		column: 'Category' text: [ :each | each protocol name ]
]

{ #category : '*SwiftyPharo' }
Behavior >> swpMethods [
	^ ((self methods , self class methods)
		asSortedCollection: [ :a :b | a selector <= b selector ]) asArray
]
