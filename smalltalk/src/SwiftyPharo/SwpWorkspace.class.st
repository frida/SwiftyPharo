"
The bindings a session's snippets share, and the requestor the compiler asks for
them. It is the playground's own scripting model, made non-interactive so an
undeclared name binds or fails cleanly rather than reaching for a dialog that a
headless image has no way to show.
"
Class {
	#name : 'SwpWorkspace',
	#superclass : 'SpCodeScriptingInteractionModel',
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'testing' }
SwpWorkspace >> interactive [
	^ false
]

{ #category : 'compiling' }
SwpWorkspace >> notify: aString at: anInteger in: aStream [
	"The compiler reports a parse error by asking its requestor to show it. With
	no editor to show it in, raise it instead, so the host sees the message the
	editor would have -- not a failure reaching for a selection that is not there."

	^ (SwpEvaluationError new position: anInteger) signal: ((aString endsWith: ' ->')
			 ifTrue: [ aString allButLast: 3 ]
			 ifFalse: [ aString ])
]
