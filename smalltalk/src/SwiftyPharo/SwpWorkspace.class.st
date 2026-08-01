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
