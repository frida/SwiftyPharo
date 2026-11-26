Class {
	#name : 'SwpColumnsTest',
	#superclass : 'TestCase',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'tests' }
SwpColumnsTest >> testAColumnDeclaresNothingOfItsOwn [
	self
		assert: (self columnsOf: #gtPlainFor:)
		equals: {
				{ 'title' -> 'Index' } asDictionary.
				{ 'title' -> 'Number' } asDictionary.
				{ 'title' -> 'Square' } asDictionary }
]

{ #category : 'tests' }
SwpColumnsTest >> testEachColumnSaysHowItIsSized [
	self
		assert: (self columnsOf: #gtSizedFor:) allButFirst
		equals: {
				{ 'title' -> 'Address'. 'fitContent' -> true. 'priority' -> 1 } asDictionary.
				{ 'title' -> 'Instruction'. 'weight' -> 2. 'minimumCharacters' -> 16 } asDictionary.
				{ 'title' -> 'Comment'. 'weight' -> 1 } asDictionary.
				{ 'title' -> 'Bytes'. 'fitContent' -> true. 'priority' -> 4 } asDictionary.
				{ 'title' -> 'Icon'. 'width' -> 36 } asDictionary }
]

{ #category : 'tests' }
SwpColumnsTest >> testRawFitsItsVariables [
	self
		assert: ((SwpViewCollector declarationOf: self rawView) at: #columns)
		equals: {
				(Dictionary new at: #title put: 'Index'; yourself).
				(Dictionary new at: #title put: 'Variable'; at: #fitContent put: true; yourself).
				(Dictionary new at: #title put: 'Value'; yourself) }
]

{ #category : 'tests' }
SwpColumnsTest >> testRawNamesEachVariable [
	self
		assert: ((self rawView itemsFrom: 1 count: 3) collect: [ :cells | (cells at: 2) at: 'text' ])
		equals: #( 'self' 'x' 'y' )
]

{ #category : 'accessing' }
SwpColumnsTest >> columnsOf: aSelector [
	| session reply |
	session := SwpSession new.
	reply := STONJSON fromString: (session answer: (STONJSON fromString: (STONJSON toString: {
					   (#op -> 'views').
					   (#handle -> (session handleFor: SwpColumnsProbe new)) } asDictionary))).
	^ ((reply at: 'views') detect: [ :each | (each at: 'methodSelector') = aSelector ]) at: 'columns'
]

{ #category : 'accessing' }
SwpColumnsTest >> rawView [
	^ (SwpViewCollector viewsFor: 3 @ 4) detect: [ :each | each title = 'Raw' ]
]
