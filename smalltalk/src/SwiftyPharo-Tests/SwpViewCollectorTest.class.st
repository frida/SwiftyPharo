Class {
	#name : 'SwpViewCollectorTest',
	#superclass : 'TestCase',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'tests' }
SwpViewCollectorTest >> testTheViewsThatWorkStay [
	self assert: ((self declarationOf: #gtSummaryFor:) at: #text) equals: 'still here'
]

{ #category : 'tests' }
SwpViewCollectorTest >> testAViewThatRaisesShowsItsError [
	| declaration |
	declaration := self declarationOf: #gtRaisingFor:.
	self assert: (declaration at: #viewName) equals: 'text'.
	self assert: (declaration at: #title) equals: 'Error'.
	self assert: (declaration at: #text) equals: 'gtRaisingFor: raised ' , self frobnicateDescription
]

{ #category : 'tests' }
SwpViewCollectorTest >> testAViewAnsweringNilSaysSo [
	self
		assert: ((self declarationOf: #gtNilFor:) at: #text)
		equals: 'gtNilFor: answered nil, which is not a view'
]

{ #category : 'tests' }
SwpViewCollectorTest >> testAFailingStencilShowsItsError [
	| declaration |
	declaration := self declarationOf: #gtFailingChartFor:.
	self assert: (declaration at: #title) equals: 'Chart (Error)'.
	self assert: (declaration at: #text) equals: 'gtFailingChartFor: raised ' , ZeroDivide new description
]

{ #category : 'tests' }
SwpViewCollectorTest >> testAStencilAnsweringNoChartSaysSo [
	self
		assert: ((self declarationOf: #gtNotAChartFor:) at: #text)
		equals: 'gtNotAChartFor: raised Error: the stencil answered 42, which is not a chart'
]

{ #category : 'tests' }
SwpViewCollectorTest >> testAForwardNamesTheViewItReached [
	self
		assert: ((self declarationOf: #gtForwardFor:) at: #text)
		equals: 'gtForwardFor: raised Error: gtRaisingFor: raised ' , self frobnicateDescription
]

{ #category : 'tests' }
SwpViewCollectorTest >> testAPaintingThatRaisesShowsItsError [
	| declaration |
	declaration := self declarationOf: #gtPaintingFor:.
	self assert: (declaration at: #title) equals: 'Painting (Error)'.
	self assert: (declaration at: #text) equals: 'gtPaintingFor: raised ' , ZeroDivide new description
]

{ #category : 'tests' }
SwpViewCollectorTest >> testAViewMethodStillRaisesWhenSentDirectly [
	self should: [ (SwpBrokenProbe new gtFailingChartFor: SwpEmptyView new) declaration ] raise: ZeroDivide
]

{ #category : 'accessing' }
SwpViewCollectorTest >> declarationOf: aSelector [
	^ (SwpViewCollector declarationsFor: SwpBrokenProbe new) detect: [ :each |
		  (each at: #methodSelector) = aSelector ]
]

{ #category : 'accessing' }
SwpViewCollectorTest >> frobnicateDescription [
	^ [ SwpTextView new frobnicate ] on: MessageNotUnderstood do: [ :error | error return: error description ]
]
