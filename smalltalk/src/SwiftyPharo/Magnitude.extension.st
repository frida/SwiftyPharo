Extension { #name : 'Magnitude' }

{ #category : '*SwiftyPharo' }
Magnitude >> gtPreviewFor: aView [
	<gtView>
	^ aView text
		title: 'Preview';
		priority: 1;
		text: [ self printString ]
]
