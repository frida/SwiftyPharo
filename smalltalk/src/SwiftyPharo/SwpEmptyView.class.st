"
Handed to a <gtView> method, which converts it into the view it wants. Left as
is when the method declines to describe anything, and then dropped.
"
Class {
	#name : 'SwpEmptyView',
	#superclass : 'SwpView',
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpEmptyView >> columnedList [
	^ SwpColumnedListView new
]

{ #category : 'testing' }
SwpEmptyView >> isEmpty [
	^ true
]

{ #category : 'building' }
SwpEmptyView >> explicit [
	^ SwpExplicitView new
]

{ #category : 'building' }
SwpEmptyView >> forward [
	^ SwpForwardView new
]

{ #category : 'building' }
SwpEmptyView >> list [
	^ SwpListView new
]

{ #category : 'building' }
SwpEmptyView >> mondrian [
	^ SwpMondrianView new
]

{ #category : 'building' }
SwpEmptyView >> text [
	^ SwpTextView new
]

{ #category : 'building' }
SwpEmptyView >> textEditor [
	"Editable text has no editor here; it reads the same as a text view."

	^ SwpTextView new
]

{ #category : 'building' }
SwpEmptyView >> tree [
	^ SwpTreeView new
]

{ #category : 'accessing' }
SwpEmptyView >> typeName [
	^ 'empty'
]
