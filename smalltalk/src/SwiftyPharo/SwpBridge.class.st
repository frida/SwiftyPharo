"
Takes the requests the embedding host posts to it. The host boots the image
with an argument that installs this once startup has finished.
"
Class {
	#name : 'SwpBridge',
	#superclass : 'Object',
	#instVars : [
		'session',
		'semaphore',
		'queue',
		'current'
	],
	#classVars : [
		'Installed'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'installing' }
SwpBridge class >> install [
	^ Installed ifNil: [ Installed := self new install ]
]

{ #category : 'accessing' }
SwpBridge class >> current [
	^ Installed
]

{ #category : 'accessing' }
SwpBridge >> session [
	^ session
]

{ #category : 'installing' }
SwpBridge >> install [
	session := SwpSession new.
	semaphore := Semaphore new.
	queue := OrderedCollection new.
	[ [ self serve ] repeat ] forkAt: Processor lowIOPriority named: 'SwiftyPharo bridge'.
	self
		call: 'swifty_pharo_bridge_ready'
		parameters: { TFBasicType sint32 }
		return: TFBasicType void
		with: { Smalltalk registerExternalObject: semaphore }.
	^ self
]

{ #category : 'serving' }
SwpBridge >> serve [
	semaphore wait.
	self acceptMessages.
	self advance
]

{ #category : 'serving' }
SwpBridge >> acceptMessages [
	| message |
	[ (message := self nextMessage) notNil ] whileTrue: [ self accept: message ]
]

{ #category : 'serving' }
SwpBridge >> nextMessage [
	| address |
	address := self
		call: 'swifty_pharo_next_message'
		parameters: #()
		return: TFBasicType pointer
		with: #().
	address isNull ifTrue: [ ^ nil ].
	^ [ STONJSON fromString: address readString utf8Decoded ] ensure: [ address free ]
]

{ #category : 'serving' }
SwpBridge >> accept: aMessage [
	aMessage at: #interrupt ifPresent: [ :id | ^ self interrupt: id ].
	queue addLast: (SwpRequest id: (aMessage at: #id) request: (aMessage at: #request))
]

{ #category : 'serving' }
SwpBridge >> interrupt: anID [
	(current notNil and: [ current id = anID ]) ifTrue: [ ^ current interruptIn: self ].
	queue
		detect: [ :each | each id = anID ]
		ifFound: [ :each |
			queue remove: each.
			self interrupted: each ]
]

{ #category : 'serving' }
SwpBridge >> advance [
	(current notNil and: [ current isFinished ]) ifTrue: [
		self deliver: current.
		current := nil ].
	(current isNil and: [ queue notEmpty ]) ifTrue: [
		current := queue removeFirst.
		current runIn: self ]
]

{ #category : 'serving' }
SwpBridge >> deliver: aRequest [
	aRequest answer ifNil: [ ^ self interrupted: aRequest ].
	self
		call: 'swifty_pharo_reply'
		parameters: { TFBasicType sint64. TFBasicType pointer }
		return: TFBasicType void
		with: { aRequest id. aRequest answer }
]

{ #category : 'serving' }
SwpBridge >> interrupted: aRequest [
	aRequest releaseHandlesIn: session.
	self
		call: 'swifty_pharo_interrupted'
		parameters: { TFBasicType sint64 }
		return: TFBasicType void
		with: { aRequest id }
]

{ #category : 'serving' }
SwpBridge >> wake [
	semaphore signal
]

{ #category : 'calling' }
SwpBridge >> call: aName parameters: aParameterTypes return: aReturnType with: aCollection [
	| function lent arguments |
	function := TFExternalFunction
		fromAddress: (ExternalAddress loadSymbol: aName module: nil)
		definition: (TFFunctionDefinition parameterTypes: aParameterTypes returnType: aReturnType).
	lent := OrderedCollection new.
	arguments := aCollection collect: [ :each |
		each isString
			ifTrue: [ lent add: (self cString: each) ]
			ifFalse: [ each ] ].
	^ [ TFSameThreadRunner uniqueInstance invokeFunction: function withArguments: arguments ]
		ensure: [ lent do: [ :each | each free ] ]
]

{ #category : 'calling' }
SwpBridge >> cString: aString [
	| bytes address |
	bytes := aString utf8Encoded.
	address := ExternalAddress allocate: bytes size + 1.
	1 to: bytes size do: [ :index | address unsignedByteAt: index put: (bytes at: index) ].
	address unsignedByteAt: bytes size + 1 put: 0.
	^ address
]
