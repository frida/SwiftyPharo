Class {
	#name : 'SwpMondrianView',
	#superclass : 'SwpView',
	#instVars : [
		'paintingBlock',
		'captured'
	],
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'building' }
SwpMondrianView >> painting: aBlock [
	paintingBlock := aBlock
]

{ #category : 'accessing' }
SwpMondrianView >> captured [
	^ captured ifNil: [ captured := self capture ]
]

{ #category : 'building' }
SwpMondrianView >> capturedMondrian: aMondrian [

	captured := aMondrian
]

{ #category : 'accessing' }
SwpMondrianView >> capture [
	| mondrian |
	mondrian := SwpMondrian new.
	paintingBlock ifNotNil: [
		[ paintingBlock value: mondrian ] on: Error do: [ :error | nil ] ].
	^ mondrian
]

{ #category : 'testing' }
SwpMondrianView >> isEmpty [
	^ self captured nodeModels isEmpty
]

{ #category : 'accessing' }
SwpMondrianView >> typeName [
	^ 'graph'
]

{ #category : 'accessing' }
SwpMondrianView >> sentItemAt: anIndex [
	^ self captured nodeModels at: anIndex
]

{ #category : 'converting' }
SwpMondrianView >> declaration [
	^ super declaration
		  at: #graph put: self captured graphDeclaration;
		  yourself
]
