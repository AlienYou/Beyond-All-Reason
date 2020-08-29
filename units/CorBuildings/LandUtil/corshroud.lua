return {
	corshroud = {
		acceleration = 0,
		activatewhenbuilt = true,
		brakerate = 0,
		buildangle = 8192,
		buildcostenergy = 20000,
		buildcostmetal = 130,
		buildinggrounddecaldecayspeed = 30,
		buildinggrounddecalsizex = 3.8,
		buildinggrounddecalsizey = 3.8,
		buildinggrounddecaltype = "decals/corshroud_aoplane.dds",
		buildpic = "CORSHROUD.PNG",
		buildtime = 9392,
		canattack = false,
		canrepeat = false,
		category = "ALL NOTLAND NOTSUB NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE EMPABLE",
		collisionvolumeoffsets = "0 16 -2",
		collisionvolumescales = "34 93 34",
		collisionvolumetype = "CylY",
		corpse = "DEAD",
		description = "Long-Range Jamming Tower",
		energyuse = 125,
		explodeas = "smallBuildingexplosiongeneric",
		footprintx = 2,
		footprintz = 2,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 800,
		maxslope = 10,
		maxwaterdepth = 0,
		name = "Shroud",
		objectname = "Units/CORSHROUD.s3o",
		onoffable = true,
		radardistancejam = 700,
		script = "Units/CORSHROUD.cob",
		seismicsignature = 0,
		selfdestructas = "smallBuildingExplosionGenericSelfd",
		sightdistance = 155,
		usebuildinggrounddecal = true,
		yardmap = "oooo",
		customparams = {
			model_author = "Mr Bob",
			normaltex = "unittextures/cor_normal.dds",
			removestop = true,
			removewait = true,
			subfolder = "corbuildings/landutil",
			techlevel = 2,
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "-7.38106536865 2.64404296892e-05 2.18940734863",
				collisionvolumescales = "57.2317047119 61.2454528809 48.0499572754",
				collisionvolumetype = "Box",
				damage = 480,
				description = "Shroud Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 20,
				hitdensity = 100,
				metal = 81,
				object = "Units/corshroud_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				collisionvolumescales = "35.0 4.0 6.0",
				collisionvolumetype = "cylY",
				damage = 240,
				description = "Shroud Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 32,
				object = "Units/cor2X2A.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sfxtypes = {
			pieceexplosiongenerators = {
				[1] = "deathceg2",
				[2] = "deathceg3",
				[3] = "deathceg4",
			},
		},
		sounds = {
			canceldestruct = "cancel2",
			underattack = "warning1",
			cant = {
				[1] = "cantdo4",
			},
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			ok = {
				[1] = "kbcormov",
			},
			select = {
				[1] = "radjam2",
			},
		},
	},
}