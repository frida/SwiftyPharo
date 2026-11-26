Class {
	#name : 'SwpRequest',
	#superclass : 'Object',
	#instVars : [
		'id',
		'request',
		'process',
		'answer',
		'finished',
		'unwound',
		'handles'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'instance creation' }
SwpRequest class >> id: anID request: aDictionary [
	^ self new setID: anID request: aDictionary
]

{ #category : 'accessing' }
SwpRequest class >> unwindGrace [
	^ 2 seconds
]

{ #category : 'initialization' }
SwpRequest >> setID: anID request: aDictionary [
	id := anID.
	request := aDictionary.
	finished := false.
	unwound := Semaphore new.
	handles := OrderedCollection new
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
	process := [
		[ SwpRequestHandles value: handles during: [ answer := self answerIn: aBridge session ] ]
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
	unwound signal.
	aBridge wake
]

{ #category : 'interrupting' }
SwpRequest >> interruptIn: aBridge [
	finished ifTrue: [ ^ self ].
	[	process terminate.
		self finishIn: aBridge ] forkAt: process priority + 1 named: 'SwiftyPharo interrupt ', id printString.
	[ (unwound waitTimeoutMilliseconds: self class unwindGrace asMilliSeconds)
		ifTrue: [ self abandonIn: aBridge ] ] forkAt: Processor lowIOPriority
]

{ #category : 'interrupting' }
SwpRequest >> abandonIn: aBridge [
	process suspend.
	finished := true.
	aBridge wake
]

{ #category : 'interrupting' }
SwpRequest >> releaseHandlesIn: aSession [
	handles do: [ :each | aSession release: each ]
]
