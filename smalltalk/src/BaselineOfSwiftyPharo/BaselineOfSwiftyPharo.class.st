Class {
	#name : 'BaselineOfSwiftyPharo',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfSwiftyPharo',
	#package : 'BaselineOfSwiftyPharo'
}

{ #category : 'baselines' }
BaselineOfSwiftyPharo >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			package: 'SwiftyPharo';
			package: 'SwiftyPharo-Tests' with: [ spec requires: 'SwiftyPharo' ].
		spec
			group: 'core' with: #('SwiftyPharo');
			group: 'tests' with: #('SwiftyPharo-Tests');
			group: 'default' with: #('SwiftyPharo') ]
]
