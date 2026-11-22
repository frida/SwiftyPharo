"
Stands in for a view that could not be built, saying what went wrong, the way
Glamorous Toolkit shows an error view in place of a broken one.
"
Class {
	#name : 'SwpErrorView',
	#superclass : 'SwpTextView',
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'instance creation' }
SwpErrorView class >> of: aSelector saying: aString [
	^ self new
		  methodSelector: aSelector;
		  title: 'Error';
		  text: aSelector , ' ' , aString;
		  yourself
]

{ #category : 'instance creation' }
SwpErrorView class >> replacing: aView saying: aString [
	^ (self of: aView methodSelector saying: aString)
		  title: aView title , ' (Error)';
		  priority: aView priority;
		  yourself
]
