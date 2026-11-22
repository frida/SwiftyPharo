"
Declares views that fail in each of the ways an object's author can make one
fail.
"
Class {
	#name : 'SwpBrokenProbe',
	#superclass : 'Object',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'views' }
SwpBrokenProbe >> gtSummaryFor: aView [
	<gtView>
	^ aView text
		title: 'Summary';
		priority: 10;
		text: [ 'still here' ]
]

{ #category : 'views' }
SwpBrokenProbe >> gtRaisingFor: aView [
	<gtView>
	^ aView text
		title: 'Raising';
		text: [ 'never shown' ];
		frobnicate
]

{ #category : 'views' }
SwpBrokenProbe >> gtNilFor: aView [
	<gtView>
	^ nil
]

{ #category : 'views' }
SwpBrokenProbe >> gtFailingChartFor: aView [
	<gtView>
	^ aView explicit
		title: 'Chart';
		stencil: [ 1 / 0 ]
]

{ #category : 'views' }
SwpBrokenProbe >> gtNotAChartFor: aView [
	<gtView>
	^ aView explicit
		title: 'Not a chart';
		stencil: [ 42 ]
]

{ #category : 'views' }
SwpBrokenProbe >> gtForwardFor: aView [
	<gtView>
	^ aView forward
		title: 'Forward';
		object: [ self ];
		view: #gtRaisingFor:
]

{ #category : 'views' }
SwpBrokenProbe >> gtPaintingFor: aView [
	<gtView>
	^ aView mondrian
		title: 'Painting';
		painting: [ :mondrian | 1 / 0 ]
]
