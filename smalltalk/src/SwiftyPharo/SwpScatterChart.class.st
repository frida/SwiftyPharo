"
A scatter plot, standing in for GtPlotterScatterChart. The dot elements it would
draw are ignored; a native frontend draws its own points.
"
Class {
	#name : 'SwpScatterChart',
	#superclass : 'SwpXYChart',
	#category : 'SwiftyPharo',
	#package : 'SwiftyPharo'
}

{ #category : 'accessing' }
SwpScatterChart >> kind [
	^ 'scatter'
]
