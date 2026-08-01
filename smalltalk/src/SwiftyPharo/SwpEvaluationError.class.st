"
A compile error a snippet raised, carrying where in the source it sits so the
host can mark the spot, not just the message.
"
Class {
	#name : 'SwpEvaluationError',
	#superclass : 'Error',
	#instVars : [
		'position'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpEvaluationError >> position [
	^ position
]

{ #category : 'accessing' }
SwpEvaluationError >> position: anInteger [
	position := anInteger
]
