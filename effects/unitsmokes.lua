return {
  ["unitsmoke"] = {
        smoke = {
         air                = true,
         class              = [[CSimpleParticleSystem]],
         count              = 1,
         ground             = true,
         water              = true,
         properties = {
           airdrag            = 0.6,
           colormap           = [[0.13 0.12 0.05 0.22   0.12 0.1 0.075 0.34   0.11 0.105 0.1 0.28   0.085 0.085 0.085 0.21    0.04 0.04 0.04 0.1   0 0 0 0.01]],
           directional        = true,
           emitrot            = 90,
           emitrotspread      = 5,
           emitvector         = [[0.0, 1, 0.0]],
           gravity            = [[0.0, -0.025, 0.0]],
           numparticles       = 1,
           particlelife       = 33,
           particlelifespread = 25,
           particlesize       = 5,
           particlesizespread = 3.5,
           particlespeed      = 0.8,
           particlespeedspread = 1,
           pos                = [[0.0, 1, 0.0]],
           sizegrowth         = 0.09,
           sizemod            = 1,
           texture            = [[dirt]],
           useairlos          = true,
         },
    },
  },
    ["unitsmokefire"] = {
        smoke = {
         air                = true,
         class              = [[CSimpleParticleSystem]],
         count              = 1,
         ground             = true,
         water              = true,
         properties = {
           airdrag            = 0.6,
           colormap           = [[0.13 0.12 0.05 0.22   0.12 0.1 0.075 0.34   0.11 0.105 0.1 0.28   0.085 0.085 0.085 0.21    0.04 0.04 0.04 0.1   0 0 0 0.01]],
           directional        = true,
           emitrot            = 90,
           emitrotspread      = 5,
           emitvector         = [[0.0, 1, 0.0]],
           gravity            = [[0.0, -0.025, 0.0]],
           numparticles       = 1,
           particlelife       = 33,
           particlelifespread = 25,
           particlesize       = 6,
           particlesizespread = 4,
           particlespeed      = 1,
           particlespeedspread = 1,
           pos                = [[0.0, 1, 0.0]],
           sizegrowth         = 0.08,
           sizemod            = 1,
           texture            = [[dirt]],
           useairlos          = true,
         },
    },
       fire = {
         air                = true,
         class              = [[CSimpleParticleSystem]],
         count              = 1,
         ground             = true,
         water              = true,
         properties = {
           airdrag            = 0.25,
           colormap           = [[0.9 0.65 0.3 0.15   0.44 0.22 0.08 0.2    0.14 0.037 0.01 0.17    0.02 0.005 0.006 0.1	 0 0 0 0.01]],
           directional        = true,
           emitrot            = 90,
           emitrotspread      = 5,
           emitvector         = [[0.0, 1, 0.0]],
           gravity            = [[0.0, 0.1, 0.0]],
           numparticles       = 1,
           particlelife       = 33,
           particlelifespread = 10,
           particlesize       = 9,
           particlesizespread = 5,
           particlespeed      = 0.5,
           particlespeedspread = 2.5,
           pos                = [[0.0, 2, 0.0]],
           sizegrowth         = -0.05,
           sizemod            = 0.9,
           texture            = [[dirt]],
           useairlos          = true,
         },
       },
       fireglow = {
         air                = true,
         class              = [[CSimpleParticleSystem]],
         count              = 1,
         ground             = true,
         water              = true,
         properties = {
           airdrag            = 0,
           colormap           = [[0.085 0.066 0.02 0.005   0 0 0 0.01]],
           directional        = true,
           emitrot            = 90,
           emitrotspread      = 0,
           emitvector         = [[0.0, 1, 0.0]],
           gravity            = [[0.0, 0.0, 0.0]],
           numparticles       = 1,
           particlelife       = 8,
           particlelifespread = 0,
           particlesize       = 100,
           particlesizespread = 10,
           particlespeed      = 0,
           particlespeedspread = 0,
           pos                = [[0.0, 0, 0.0]],
           sizegrowth         = -0.5,
           sizemod            = 1,
           texture            = [[glow]],
           useairlos          = true,
         },
       },
  },
     ["unitfire"] = {
       fire = {
         air                = true,
         class              = [[CSimpleParticleSystem]],
         count              = 1,
         ground             = true,
         water              = true,
         properties = {
           airdrag            = 0.25,
           colormap           = [[0.9 0.65 0.3 0.15   0.44 0.22 0.08 0.2    0.14 0.037 0.01 0.17    0.02 0.005 0.006 0.1	 0 0 0 0.01]],
           directional        = true,
           emitrot            = 90,
           emitrotspread      = 5,
           emitvector         = [[0.0, 1, 0.0]],
           gravity            = [[0.0, 0.1, 0.0]],
           numparticles       = 1,
           particlelife       = 33,
           particlelifespread = 10,
           particlesize       = 9,
           particlesizespread = 5,
           particlespeed      = 0.5,
           particlespeedspread = 2.5,
           pos                = [[0.0, 2, 0.0]],
           sizegrowth         = -0.05,
           sizemod            = 0.9,
           texture            = [[flame]],
           useairlos          = true,
         },
       },
       fireglow = {
         air                = true,
         class              = [[CSimpleParticleSystem]],
         count              = 1,
         ground             = true,
         water              = true,
         properties = {
           airdrag            = 0,
           colormap           = [[0.085 0.066 0.02 0.005   0 0 0 0.01]],
           directional        = true,
           emitrot            = 90,
           emitrotspread      = 0,
           emitvector         = [[0.0, 1, 0.0]],
           gravity            = [[0.0, 0.0, 0.0]],
           numparticles       = 1,
           particlelife       = 8,
           particlelifespread = 0,
           particlesize       = 100,
           particlesizespread = 10,
           particlespeed      = 0,
           particlespeedspread = 0,
           pos                = [[0.0, 0, 0.0]],
           sizegrowth         = -0.5,
           sizemod            = 1,
           texture            = [[glow2]],
           useairlos          = true,
         },
       },
  },
  ["unitsparkles"] = {
      lightningballs = {
        air                = true,
        class              = [[CSimpleParticleSystem]],
        count              = 1,
        ground             = true,
        water              = true,
        underwater		 = true,
        properties = {
          airdrag            = 1,
          colormap           = [[0 0 0 0.01 1 1 1 0.01 0 0 0 0.01]],
          directional        = true,
          emitrot            = 80,
          emitrotspread      = 0,
          emitvector         = [[0, 1, 0]],
          gravity            = [[0, 0, 0]],
          numparticles       = 1,
          particlelife       = 6,
          particlelifespread = 0,
          particlesize       = 2,
          particlesizespread = 7.5,
          particlespeed      = 0.01,
          particlespeedspread = 0,
          pos                = [[-10 r10, 1.0, -10 r10]],
          sizegrowth         = 0,
          sizemod            = 1.0,
          texture            = [[lightbw]],
        },
      },
  },
}

