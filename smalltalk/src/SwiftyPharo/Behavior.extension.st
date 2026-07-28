Extension { #name : 'Behavior' }

{ #category : '*SwiftyPharo' }
Behavior >> swpMethodsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Methods';
		priority: 1;
		items: [ (self methods asSortedCollection: [ :a :b | a selector <= b selector ]) asArray ];
		column: 'Method' text: [ :each | each selector ];
		column: 'Category' text: [ :each | each protocol name ]
]
