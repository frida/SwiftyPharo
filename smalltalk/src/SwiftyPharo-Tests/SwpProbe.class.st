"
Declares views the way an object written for Glamorous Toolkit would.
"
Class {
	#name : 'SwpProbe',
	#superclass : 'Object',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'views' }
SwpProbe >> gtNumbersFor: aView [
	<gtView>
	^ aView list
		title: 'Numbers';
		priority: 10;
		items: [ 1 to: 5 ];
		itemText: [ :each | 'n=', each printString ]
]

{ #category : 'views' }
SwpProbe >> gtNothingFor: aView [
	<gtView>
	^ aView
]

{ #category : 'views' }
SwpProbe >> gtSummaryFor: aView [
	<gtView>
	^ aView text
		title: 'Summary';
		priority: 20;
		text: [ 'a probe' ]
]
