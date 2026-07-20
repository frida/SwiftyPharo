Extension { #name : 'SDLOSXPlatform' }

{ #category : '*SwiftyPharo' }
SDLOSXPlatform >> initPlatformSpecific [
	"The host owns the application menu. Building Pharo's own reaches AppKit
	from the VM thread, which AppKit refuses."
]
