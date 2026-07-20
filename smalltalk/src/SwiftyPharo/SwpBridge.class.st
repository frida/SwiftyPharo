"
Hands the embedding host a C function pointer it can call to run a request.
The runner is bound when the callback is built: assigning it afterwards leaves
calls arriving on a foreign thread hanging.
"
Class {
	#name : 'SwpBridge',
	#superclass : 'Object',
	#instVars : [
		'callback',
		'session',
		'worker'
	],
	#classVariables : [
		'Installed'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'installing' }
SwpBridge class >> install [
	^ Installed ifNil: [ Installed := self new install ]
]

{ #category : 'installing' }
SwpBridge class >> installOnStartUp [
	"Registration is explicit: a class-side initialize would run whenever the
	package is loaded, including in the plain VM that builds the image, where
	there is no host to hand a thunk to."

	SessionManager default registerUserClassNamed: self name
]

{ #category : 'installing' }
SwpBridge class >> startUp: isImageStarting [
	"Thunks do not survive a snapshot, so the callback is rebuilt every boot."

	isImageStarting ifTrue: [
		Installed := nil.
		self install ]
]

{ #category : 'installing' }
SwpBridge >> install [
	session := SwpSession new.
	worker := TFWorker named: 'swiftypharo'.
	worker ensureInitialized.
	callback := TFCallback
		forCallback: [ :request :response :capacity |
			self respondTo: request into: response capacity: capacity ]
		parameters: { TFBasicType pointer. TFBasicType pointer. TFBasicType sint32 }
		returnType: TFBasicType sint32
		runner: worker.
	self registerThunk.
	^ self
]

{ #category : 'installing' }
SwpBridge >> registerThunk [
	| address definition function |
	address := ExternalAddress loadSymbol: 'swifty_pharo_thunk_ready' module: nil.
	definition := TFFunctionDefinition
		parameterTypes: { TFBasicType pointer }
		returnType: TFBasicType void.
	function := TFExternalFunction fromAddress: address definition: definition.
	TFSameThreadRunner uniqueInstance invokeFunction: function withArguments: { callback thunk }
]

{ #category : 'requests' }
SwpBridge >> respondTo: aRequestAddress into: aResponseAddress capacity: aCapacity [
	| answer |
	answer := [ session handleRequestJson: aRequestAddress readString ]
		on: Error
		do: [ :e | '{"error":"', e class name, '"}' ].
	^ self write: answer to: aResponseAddress capacity: aCapacity
]

{ #category : 'requests' }
SwpBridge >> write: aString to: anAddress capacity: aCapacity [
	"Answers the length the host needs, so a short buffer can be retried."

	| bytes count |
	bytes := aString utf8Encoded.
	count := bytes size min: aCapacity - 1.
	1 to: count do: [ :i | anAddress unsignedByteAt: i put: (bytes at: i) ].
	anAddress unsignedByteAt: count + 1 put: 0.
	^ bytes size
]
