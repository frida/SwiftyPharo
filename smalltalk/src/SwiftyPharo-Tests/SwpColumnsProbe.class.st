Class {
	#name : 'SwpColumnsProbe',
	#superclass : 'Object',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'views' }
SwpColumnsProbe >> gtPlainFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Plain';
		items: [ #( 1 2 ) ];
		column: 'Number' text: [ :each | each printString ];
		column: 'Square' text: [ :each | each squared printString ]
]

{ #category : 'views' }
SwpColumnsProbe >> gtSizedFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Sized';
		items: [ #( 1 2 ) ];
		column: 'Address' do: [ :column |
			column
				text: [ :each | each printStringHex ];
				fitContent;
				priority: 1 ];
		column: 'Instruction' do: [ :column |
			column
				text: [ :each | each printString ];
				weight: 2;
				minimumCharacters: 16 ];
		column: 'Comment' text: [ :each | '' ] weight: 1;
		column: 'Bytes' do: [ :column |
			column
				text: [ :each | each printStringHex ];
				width: 40;
				fitContent;
				priority: 4 ];
		column: 'Icon' icon: [ :each | nil ] width: 36
]
