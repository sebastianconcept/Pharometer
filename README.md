# Pharometer

[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE.txt)
[![Release](https://img.shields.io/github/v/tag/sebastianconcept/Pharometer?label=release)](https://github.com/sebastianconcept/Pharometer/releases)

A Zinc delegate for sampling Pharo metrics in a InfluxDB friendly format.

`Pharometer` is a Zinc delegate that renders in `InfluxDB` format all the metrics you had me setup to measure.

## Load

```smalltalk
Metacello new
  baseline: 'Pharometer';
  repository: 'github://sebastianconcept/Pharometer:v1.0.0';
  load.
```

## Setup

You can instantiate `Pharometer` and add the meters. 

Example:

```smalltalk
| pharometer |

pharometer := Pharometer named: 'pharo'.
pharometer addContextBuilder: [ :ctx | ctx at: #sockets put: Socket allInstances ].
pharometer addTag: #app value: 'backend42'.
pharometer addTag: #image value: [ Smalltalk image imageDirectory pathString ].
pharometer addField: #totalSockets value: [:ctx| (ctx at: #sockets) size  ].
pharometer addField: #openSockets value: [:ctx| ((ctx at: #sockets) select:[ :e | e isConnected ]) size ].
pharometer addField: #semaphores value: [ Semaphore allInstances size ].

pharometer render.
```

## How to run

If you start it with this, hitting 8890 with a `GET /` will give you the measurments using that `render` method.

```
server := ZnServer on: 8890.
server delegate: pharometer.
server start.
```

## Presets

Check my handy presets that could be useful to monitor during operations:

- addMemoryMetrics
- addSocketMetrics
- addThreadMetrics
- addOtherMetrics

## A handy observability default

```smalltalk
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
