Class {
	#name : 'SwpRequest',
	#superclass : 'Object',
	#instVars : [
		'id',
		'request',
		'answer',
		'finished'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'instance creation' }
SwpRequest class >> id: anID request: aDictionary [
	^ self new setID: anID request: aDictionary
]

{ #category : 'initialization' }
SwpRequest >> setID: anID request: aDictionary [
	id := anID.
	request := aDictionary.
	finished := false
]

{ #category : 'accessing' }
SwpRequest >> id [
	^ id
]

{ #category : 'accessing' }
SwpRequest >> answer [
	^ answer
]

{ #category : 'testing' }
SwpRequest >> isFinished [
	^ finished
]

{ #category : 'running' }
SwpRequest >> runIn: aBridge [
	[ [ answer := self answerIn: aBridge session ]
		ensure: [ self finishIn: aBridge ] ]
		forkAt: Processor userSchedulingPriority
		named: 'SwiftyPharo request ', id printString
]

{ #category : 'running' }
SwpRequest >> answerIn: aSession [
	^ [ aSession answer: request ]
		on: Error
		do: [ :e | '{"error":"', e class name, '"}' ]
]

{ #category : 'running' }
SwpRequest >> finishIn: aBridge [
	finished := true.
	aBridge wake
]
