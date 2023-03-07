"
I am a Zinc delegate that renders in `InfluxDB` format all the metrics you had me setup to measure.

## Setup
You can instantiate me and add the meters. Example:

```
pm := Pharometer named: 'pharo'.
pm contextBuilder: [ :ctx | ctx at: #sockets put: Socket allInstances ].
pm addTag: #app value: 'backend42'.
pm addTag: #image value: [ Smalltalk image imageDirectory pathString ].
pm addField: #totalSockets value: [:ctx| (ctx at: #sockets) size  ].
pm addField: #openSockets value: [:ctx| ((ctx at: #sockets) select:[ :e | e isConnected ]) size ].
pm addField: #semaphores value: [ Semaphore allInstances size ].

pm render. 
```

## How to run
If you start it with this, hitting 8890 with a `GET /` will gve you measurments.

```
server := ZnServer on: 8890.
server delegate: pharometer.
server start.
```

## Presets
Chek my handy presets that could be useful to monitor during operations:

addMemoryMetrics
addSocketMetrics
addThreadMetrics
addOtherMetrics

## A nice observability default


```
| pm |
pm := (Pharometer named: 'pharo42')
	addMemoryMetrics;
	addSocketMetrics;
	addThreadMetrics;
	addOtherMetrics;
	yourself.
server := ZnServer on: 8890.
server delegate: pm.
server start.
```

"
Class {
	#name : #Pharometer,
	#superclass : #Object,
	#instVars : [
		'name',
		'tags',
		'fields',
		'context',
		'contextBuilders'
	],
	#category : #Pharometer
}

{ #category : #'instance creation' }
Pharometer class >> named: aString [

	^ self new name: aString
]

{ #category : #actions }
Pharometer >> addContextBuilder: aBlock [

	self contextBuilders add: aBlock
]

{ #category : #actions }
Pharometer >> addField: aSymbol value: aBlock [

	^ self fields at: aSymbol put: aBlock
]

{ #category : #presets }
Pharometer >> addMemoryMetrics [

	self
		addField: #freeSize value: [ Smalltalk vm freeSize ];
		addField: #edenSpaceSize value: [ Smalltalk vm edenSpaceSize ];
		addField: #youngSpaceSize value: [ Smalltalk vm youngSpaceSize ];
		addField: #freeOldSpaceSize
		value: [ Smalltalk vm freeOldSpaceSize ];
		addField: #memorySize value: [ Smalltalk vm memorySize ];
		yourself
]

{ #category : #presets }
Pharometer >> addOtherMetrics [

	self
		addField: #externalObjects
		value: [ Smalltalk image externalObjects size ];
		addField: #semaphores value: [ Semaphore allInstances size ];
		yourself
]

{ #category : #presets }
Pharometer >> addSocketMetrics [

	self
		addContextBuilder: [ :ctx | 
			ctx at: #sockets put: Socket allInstances ];
		addField: #totalSockets value: [ :ctx | (ctx at: #sockets) size ];
		addField: #connectedSockets
		value: [ :ctx | 
			((ctx at: #sockets) select: [ :e | e isConnected ]) size ];
		yourself
]

{ #category : #actions }
Pharometer >> addTag: aSymbol value: aValueOrBlock [

	^ self tags at: aSymbol put: (aValueOrBlock isBlock
			   ifTrue: [ aValueOrBlock ]
			   ifFalse: [ [ aValueOrBlock ] ])
]

{ #category : #presets }
Pharometer >> addThreadMetrics [

	self
		addContextBuilder: [ :ctx | 
			ctx at: #processes put: Process allInstances ];
		addField: #totalProcesses
		value: [ :ctx | (ctx at: #processes) size ];
		addField: #suspendedProcesses
		value: [ :ctx | 
			((ctx at: #processes) select: [ :e | e isSuspended ]) size ];
		addField: #terminatedProcesses
		value: [ :ctx | 
			((ctx at: #processes) select: [ :e | e isTerminated ]) size ];
		addField: #terminatingProcesses
		value: [ :ctx | 
			((ctx at: #processes) select: [ :e | e isTerminating ]) size ];
		yourself
]

{ #category : #actions }
Pharometer >> buildContext [

	"Reset the context and make a new one based on my builders."

	context := nil.
	self contextBuilders do: [ :contextBuilder | 
		contextBuilder value: self context ]
]

{ #category : #accessing }
Pharometer >> context [

	^ context ifNil: [ context := SmallDictionary new ]
]

{ #category : #accessing }
Pharometer >> contextBuilders [

	^ contextBuilders ifNil: [ contextBuilders := OrderedCollection new ]
]

{ #category : #accessing }
Pharometer >> fields [

	^ fields ifNil: [ fields := SmallDictionary new ]
]

{ #category : #accessing }
Pharometer >> fields: anObject [

	fields := anObject
]

{ #category : #actions }
Pharometer >> handleRequest: aRequest [

	(#( GET ) includes: aRequest method) ifFalse: [ 
		^ ZnResponse badRequest: aRequest ].

	^ ZnResponse ok: (ZnEntity text: self render)
]

{ #category : #accessing }
Pharometer >> name [

	^ name ifNil: [ name := '?' ]
]

{ #category : #accessing }
Pharometer >> name: anObject [

	name := anObject
]

{ #category : #rendering }
Pharometer >> render [

	^ String streamContents: [ :stream | self renderOn: stream ]
]

{ #category : #rendering }
Pharometer >> renderFieldsOn: aStream [

	self fields isEmpty ifFalse: [ 
		fields keysAndValuesDo: [ :k :v | 
			aStream
				nextPutAll: k;
				nextPut: $=;
				nextPutAll: (v cull: context) asString;
				nextPut: $, ].
		aStream skip: -1 "to eat the last comma" ]
]

{ #category : #rendering }
Pharometer >> renderOn: aStream [

	"
https://docs.influxdata.com/influxdb/v2.6/reference/syntax/line-protocol/

// Syntax
<measurement>[,<tag_key>=<tag_value>[,<tag_key>=<tag_value>]] <field_key>=<field_value>[,<field_key>=<field_value>] [<timestamp>]

// Example
myMeasurement,tag1=value1,tag2=value2 fieldKey=""fieldValue"" 1556813561098000000
"

	self buildContext.
	aStream nextPutAll: self name.
	self renderTagsOn: aStream.
	aStream space.
	self renderFieldsOn: aStream.
	"Release potential references to measured resources quickly."
	context removeAll
]

{ #category : #rendering }
Pharometer >> renderTagsOn: aStream [

	self tags isEmpty ifFalse: [ 
		aStream nextPut: $,.
		tags keysAndValuesDo: [ :k :v | 
			aStream
				nextPutAll: k;
				nextPut: $=;
				nextPutAll: (v cull: context) asString;
				nextPut: $, ].
		aStream skip: -1 "to eat the last comma" ]
]

{ #category : #accessing }
Pharometer >> tags [

	^ tags ifNil: [ tags := SmallDictionary new ]
]

{ #category : #accessing }
Pharometer >> tags: anObject [

	tags := anObject
]
