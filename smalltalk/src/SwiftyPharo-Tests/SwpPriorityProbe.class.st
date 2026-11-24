Class {
	#name : 'SwpPriorityProbe',
	#superclass : 'Object',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'views' }
SwpPriorityProbe >> gtTwoFor: aView [
	<gtView>
	^ aView text
		title: 'Two';
		priority: 2;
		text: [ 'two' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtOneAndAHalfFor: aView [
	<gtView>
	^ aView text
		title: 'One and a half';
		priority: 1.5;
		text: [ 'one and a half' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtOneFor: aView [
	<gtView>
	^ aView text
		title: 'One';
		priority: 1;
		text: [ 'one' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtThreeQuartersFor: aView [
	<gtView>
	^ aView text
		title: 'Three quarters';
		priority: 3 / 4;
		text: [ 'three quarters' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtFiveQuartersFor: aView [
	<gtView>
	^ aView text
		title: 'Five quarters';
		priority: 1.25s2;
		text: [ 'five quarters' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtTieCFor: aView [
	<gtView>
	^ aView text
		title: 'Tie C';
		priority: 3;
		text: [ 'tie c' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtTieAFor: aView [
	<gtView>
	^ aView text
		title: 'Tie A';
		priority: 3;
		text: [ 'tie a' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtTieBFor: aView [
	<gtView>
	^ aView text
		title: 'Tie B';
		priority: 3;
		text: [ 'tie b' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtHighFor: aView [
	<gtView>
	^ aView text
		title: 'High';
		priority: 'high';
		text: [ 'never shown' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtNaNFor: aView [
	<gtView>
	^ aView text
		title: 'NaN';
		priority: Float nan;
		text: [ 'never shown' ]
]

{ #category : 'views' }
SwpPriorityProbe >> gtEndlessFor: aView [
	<gtView>
	^ aView text
		title: 'Endless';
		priority: Float infinity;
		text: [ 'endless' ]
]
