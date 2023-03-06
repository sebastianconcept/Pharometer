Class {
	#name : #BaselineOfPharometer,
	#superclass : #BaselineOf,
	#category : #BaselineOfPharometer
}

{ #category : #baselines }
BaselineOfPharometer >> baseline: spec [

	<baseline>
	spec for: #common do: [ 
		self setUpDependencies: spec.
		self setUpPackages: spec.
		spec
			group: 'Core' with: #( 'Pharometer' );
			group: 'Tests' with: #( 'Pharometer-Tests' );
			group: 'default' with: #( 'Core' ) ]
]

{ #category : #baselines }
BaselineOfPharometer >> setUpDependencies: spec [

	"Just Zinc"

]

{ #category : #baselines }
BaselineOfPharometer >> setUpPackages: spec [

	spec package: 'Pharometer' with: [ spec requires: #(  ) ].

	spec
		package: 'Pharometer-Tests'
		with: [ spec requires: #( 'Pharometer' ) ]
]
