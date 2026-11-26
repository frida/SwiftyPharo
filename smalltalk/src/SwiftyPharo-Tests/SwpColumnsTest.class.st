Class {
	#name : 'SwpColumnsTest',
	#superclass : 'TestCase',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'tests' }
SwpColumnsTest >> testRawNamesEachVariable [
	self
		assert: ((self rawView itemsFrom: 1 count: 3) collect: [ :cells | (cells at: 2) at: 'text' ])
		equals: #( 'self' 'x' 'y' )
]

{ #category : 'accessing' }
SwpColumnsTest >> rawView [
	^ (SwpViewCollector viewsFor: 3 @ 4) detect: [ :each | each title = 'Raw' ]
]
