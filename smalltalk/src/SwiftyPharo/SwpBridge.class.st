"
Hands the embedding host a C function pointer it can call to run a request.
The host boots the image with an argument that installs this once startup has
finished; building the callback from a startup handler is not dependable.
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
	answer := [ session handleRequestJson: aRequestAddress readString utf8Decoded ]
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
