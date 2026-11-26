Class {
	#name : 'SwpViewPriorityTest',
	#superclass : 'TestCase',
	#category : 'SwiftyPharo-Tests',
	#package : 'SwiftyPharo-Tests'
}

{ #category : 'tests' }
SwpViewPriorityTest >> testPrioritiesOrderAsNumbers [
	self
		assert: (self declarations collect: [ :each | each at: #methodSelector ])
		equals:
			#( #gtThreeQuartersFor: #gtOneFor: #gtFiveQuartersFor: #gtOneAndAHalfFor: #gtTwoFor: #gtTieAFor: #gtTieBFor: #gtTieCFor: #gtHighFor: #gtNaNFor: #gtEndlessFor: )
]

{ #category : 'tests' }
SwpViewPriorityTest >> testEqualPrioritiesOrderBySelector [
	self
		assert: ((self declarations select: [ :each | (each at: #priority) = 3 ]) collect: [ :each | each at: #title ])
		equals: #( 'Tie A' 'Tie B' 'Tie C' )
]

{ #category : 'tests' }
SwpViewPriorityTest >> testAPriorityThatIsNotANumberShowsItsError [
	| declaration |
	declaration := self declarationOf: #gtHighFor:.
	self assert: (declaration at: #viewName) equals: 'text'.
	self assert: (declaration at: #text) equals: 'gtHighFor: gave the priority ''high'', which is not a number'
]

{ #category : 'tests' }
SwpViewPriorityTest >> testANaNPriorityShowsItsError [
	self
		assert: ((self declarationOf: #gtNaNFor:) at: #text)
		equals: 'gtNaNFor: gave the priority Float nan, which is not a number'
]

{ #category : 'tests' }
SwpViewPriorityTest >> testEveryPriorityCrossesTheBridge [
	| session reply |
	session := SwpSession new.
	reply := STONJSON fromString: (session answer: (STONJSON fromString: (STONJSON toString: {
					   (#op -> 'views').
					   (#handle -> (session handleFor: SwpPriorityProbe new)) } asDictionary))).
	self
		assert: (((reply at: 'views') select: [ :each | self isProbed: (each at: 'methodSelector') ]) collect: [ :each |
				 each at: 'priority' ])
		equals: { 0.75. 1. 1.25. 1.5. 2. 3. 3. 3. 75. 75. Float fmax }
]

{ #category : 'accessing' }
SwpViewPriorityTest >> declarations [
	^ (SwpViewCollector declarationsFor: SwpPriorityProbe new) select: [ :each |
		  self isProbed: (each at: #methodSelector) ]
]

{ #category : 'accessing' }
SwpViewPriorityTest >> isProbed: aSelector [
	^ SwpPriorityProbe includesSelector: aSelector asSymbol
]

{ #category : 'accessing' }
SwpViewPriorityTest >> declarationOf: aSelector [
	^ self declarations detect: [ :each | (each at: #methodSelector) = aSelector ]
]
