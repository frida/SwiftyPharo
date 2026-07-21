"
Stands in for the code editor that Pharo's completion normally reads the caret
from, so a host with its own editor can complete a plain string and position.
"
Class {
	#name : 'SwpCompletionCursor',
	#superclass : 'Object',
	#instVars : [
		'source',
		'position'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'instance creation' }
SwpCompletionCursor class >> source: aString position: anInteger [
	^ self new setSource: aString position: anInteger
]

{ #category : 'initialization' }
SwpCompletionCursor >> setSource: aString position: anInteger [
	source := aString.
	position := anInteger
]

{ #category : 'accessing' }
SwpCompletionCursor >> completionToken [
	^ source copyFrom: self completionTokenStart to: position
]

{ #category : 'accessing' }
SwpCompletionCursor >> completionTokenStart [
	position to: 1 by: -1 do: [ :index |
		(self isTokenCharacter: (source at: index)) ifFalse: [ ^ index + 1 ] ].
	^ 1
]

{ #category : 'accessing' }
SwpCompletionCursor >> isTokenCharacter: aCharacter [
	^ aCharacter isAlphaNumeric or: [ aCharacter = $_ ]
]

{ #category : 'accessing' }
SwpCompletionCursor >> isScripting [
	^ true
]

{ #category : 'accessing' }
SwpCompletionCursor >> doItContext [
	^ nil
]

{ #category : 'accessing' }
SwpCompletionCursor >> doItRequestor [
	^ nil
]

{ #category : 'accessing' }
SwpCompletionCursor >> variableBindingNames [
	^ #()
]
