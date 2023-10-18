# Anybody Problem

Anybody Problem is a circom project that models the movement of any number of  `n` bodies using classic newtonian-like physics over any number of `s` steps. There are two versions:

## Anybody Problem NFT

The Anybody Problem NFT is a simulation of the bodies moving in space over time. Proofs are generated over `s` steps with `n` bodies and verified on-chain. This version is represented in the top level `nft.circom` circuit [here](./circuits/nft.circom).

## Anybody Problem Game

The Anybody Problem Game adds an additional `missiles` input that allows a user to fire missiles at the bodies in order to destroy them. This version is represented in the top level `stepState.circom` circuit [here](./circuits/stepState.circom). A very rough draft of the game can be played at https://okwme.github.io/anybody-problem. 

## Circuits

There are a number of circuits involved in Anybody Problem. They're listed below with links and short descriptions. 

> NOTICE: **Scaling Factor**  
> Due to the lack of float values in circom, the values are scaled up by a factor of 10**8. This means that the values are integers and the decimal point is implied. For example, the value `1.5` would be represented as `150000000`.

> NOTICE: **Negative Values**
> Due to the nature of finite field arithmetic, negative values are represented as `p-n` where `p` is the prime number used in the finite field and `n` is the absolute value of the negative number.  
> 
> For example, `-1` would be represented as:  `21888242871839275222246405745257275088548364400416034343698204186575808495617 - 1`  
> or  
> `21888242871839275222246405745257275088548364400416034343698204186575808495616`. 

### [AbsoluteValueSubtraction(n)](./circuits/approxMath.circom:79)
This circuit finds the absolute value difference between two numbers.

- `n` - The maximum number of bits for each input value
- `input in[2]` - An array of length 2 for each input value
- `output out` - The difference between the two values

### [AcceptableMarginOfError(n)](./circuits/approxMath.circom:60)
This circuit is used in tandem with `approxDiv` and `approxSqrt` which are both defined in [`approxMath.circom`](./circuits/approxMath.circom). When finding the approximate solution to division or the approximate square root of a value, there is an acceptable margin of error to be expected. This circuit ensures the value is within that range.
 
- `n` - The maximum number of bits for each input value
- `input expected` - The expected value
- `input actual` - The actual value
- `input marginOfError` - The margin of error
- `output out` - The output value is `0` when the difference is outside the margin of error and `1` when within the margin of error.

### [CalculateForce()](./circuits/calculateForce.circom)
This circuit calculates the gravitational force between two bodies based on their mass and position in space.
- `input in_bodies[2][5]` - An array of length 2 for each body. Each body has 5 inputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`.  These are all scaled up by a factor of 10**8.
- `output out_forces` - An array of length 2 for each force, `force_x` and `force_y`

### [DetectCollision(totalBodies)](./circuits/detectCollision.circom)
This circuit detects if a body and a missile are colliding. It does this by calculating the distance between the two and comparing it to the sum of their radii. If a collision is detected, the radius/mass of the body and the missile are returned as 0.
- `totalBodies` - The total number of bodies in the simulation
- `input bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 inputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`
- `input missile[5]` - An array of length 5 for the missile. Each missile has 5 inputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`.  These are all scaled up by a factor of 10**8.
- `output out_bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 outputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`.  These are all scaled up by a factor of 10**8.
- `output out_missile[5]` - An array of length 5 for the missile. Each missile has 5 outputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`.  These are all scaled up by a factor of 10**8.

### [ForceAccumulator(totalBodies)](./circuits/forceAccumulator.circom)
This circuit calculates the total force on each body based on the gravitational force between each pair of bodies. It limits the vector by a maximum value and updates the position of each body based on its accumulated force. If the new position is outside the boundary of the simulation, it is updated to be on the opposite side as if the area was a torus.
- `totalBodies` - The total number of bodies in the simulation
- `input in_bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 inputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`.  These are all scaled up by a factor of 10**8.
- `output out_bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 outputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`.  These are all scaled up by a factor of 10**8.

### [GetDistance(n)](./circuits/getDistance.circom)
This circuit calculates the distance between two coordinate points using `approxSqrt()` and checking the result is within an acceptable margin of error using `AcceptableMarginOfError()`.
- `n` - The maximum number of bits for each input value and expected output value.
- `input x1` - The x coordinate of the first point
- `input y1` - The y coordinate of the first point
- `input x2` - The x coordinate of the second point
- `input y2` - The y coordinate of the second point
- `output distance` - The distance between the two points

### [Limiter(n)](./circuits/limiter.circom)
This circuit limits the value of an input to a maximum value. It also accepts an alternative value that is returned if the input value is greater than the maximum.
- `n` - The maximum number of bits for each input value and expected output value.
- `input in` - The input value
- `input limit` - The maximum value
- `input rather` - The alternative value
- `output out` - The output value

### [LowerLimiter(n)](./circuits/limiter.circom:23)
This circuit limits the value of an input to a minimum value. It also accepts an alternative value that is returned if the input value is less than the minimum.
- `n` - The maximum number of bits for each input value and expected output value.
- `input in` - The input value
- `input limit` - The minimum value
- `input rather` - The alternative value
- `output out` - The output value

### [nft(totalBodies, steps)](./circuits/nft.circom)
This circuit is the top level circuit for the NFT version of Anybody Problem. It takes in the initial state of the bodies and the number of steps to simulate and outputs the resulting bodies.
- `totalBodies` - The total number of bodies in the simulation
- `steps` - The total number of steps to simulate
- `input bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 inputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`. These are all scaled up by a factor of 10**8.
- `output out_bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 outputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`. These are all scaled up by a factor of 10**8.

### [StepState(totalBodies, steps)](./circuits/stepState.circom)
This is the top level circuit for the game version of Anybody Problem. It takes in the initial state of the bodies, the number of steps to simulate and the missiles to fire and outputs the resulting bodies.
- `totalBodies` - The total number of bodies in the simulation.
- `steps` - The total number of steps to simulate.
- `input bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 inputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`. These are all scaled up by a factor of 10**8.
- `input missiles[steps + 1][5]` - An array of length `steps + 1` for each missile. Each missile has 5 inputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`. These are all scaled up by a factor of 10**8.
- `output out_bodies[totalBodies][5]` - An array of length `totalBodies` for each body. Each body has 5 outputs:  `position_x`, `position_y`, `vector_x`, `vector_y` and `radius/mass`. These are all scaled up by a factor of 10**8.


## Tests

To run rudimentary tests on the various circuits use the following command:

```bash
yarn test
```

You should see something like:
```bash
  absoluteValueSubtraction circuit
    ✔ produces a witness with valid constraints (97ms)
    ✔ has expected witness values
    ✔ has the correct output (53ms)

  acceptableMarginOfError circuit
    ✔ produces a witness with valid constraints (145ms)
    ✔ has expected witness values
    ✔ has the correct output

  calculateForceMain circuit
    ✔ produces a witness with valid constraints (1076ms)
    ✔ has expected witness values (43ms)
    ✔ has the correct output

  detectCollisionMain circuit
    ✔ produces a witness with valid constraints (855ms)
    ✔ has expected witness values
    ✔ has the correct output

  forceAccumulatorMain circuit
    ✔ produces a witness with valid constraints (232ms)
    ✔ has expected witness values (53ms)
    ✔ has the correct output

  getDistanceMain circuit
    ✔ produces a witness with valid constraints (898ms)
    ✔ has expected witness values (90ms)
    ✔ has the correct output (41ms)

  limiterMain circuit
    ✔ produces a witness with valid constraints (95ms)
    ✔ has expected witness values
    ✔ has the correct output (57ms)

  lowerLimiterMain circuit
    ✔ produces a witness with valid constraints (975ms)
    ✔ has expected witness values
    ✔ has the correct output (48ms)

  nft circuit
    ✔ produces a witness with valid constraints (1043ms)
    ✔ has expected witness values (324ms)
    ✔ has the correct output (185ms)

  stepStateMain circuit
    ✔ produces a witness with valid constraints (1520ms)
    ✔ has expected witness values (485ms)
    ✔ has the correct output (238ms)


  30 passing (28s)

✨  Done in 30.33s.
```

## Performance

Currently the project is targeting [powersOfTau28_hez_final_20.ptau](https://github.com/iden3/snarkjs/blob/master/README.md#7-prepare-phase-2) which has a limit of 1MM constraints. Below is a table of the number of constraints used by each circuit.

| Circuit | Non-Linear Constraints |
|---------|-------------|
| absoluteValueSubtraction(252) | 257 |
| acceptableMarginOfError(60) | 126 |
| calculateForce() | 1,340 |
| detectCollision(3) | 1,548 |
| forceAccumulator(3) | 6,012 |
| getDistance(252) | 1,026 |
| limiter(252) | 254 |
| lowerLimiter(252) | 254 |
| nft(3, 10) | 60,120 |
| stepState(3, 10) | 76,530 |

# built using circom-starter

A basic circom project using [Hardhat](https://github.com/nomiclabs/hardhat) and [hardhat-circom](https://github.com/projectsophon/hardhat-circom). This combines the multiple steps of the [Circom](https://github.com/iden3/circom) and [SnarkJS](https://github.com/iden3/snarkjs) workflow into your [Hardhat](https://hardhat.org) workflow.

By providing configuration containing your Phase 1 Powers of Tau and circuits, this plugin will:

1. Compile the circuits
2. Apply the final beacon
3. Output your `wasm` and `zkey` files
4. Generate and output a `Verifier.sol`

## Documentation

See the source projects for full documentation and configuration

## Install

`yarn` to install dependencies

## Development builds

`yarn circom:dev` to build deterministic development circuits.

Further, for debugging purposes, you may wish to inspect the intermediate files. This is possible with the `--debug` flag which the `circom:dev` task enables by default. You'll find them (by default) in `artifacts/circom/`

To build a single circuit during development, you can use the `--circuit` CLI parameter. For example, if you make a change to `hash.circom` and you want to _only_ rebuild that, you can run `yarn circom:dev --circuit hash`.

## Production builds

`yarn circom:prod` for production builds (using `Date.now()` as entropy)
