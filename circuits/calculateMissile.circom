pragma circom 2.1.6;

include "buses.circom";

/*
Notes on CalculateMissile()

This function calculates the movement of one missile using the following inputs:
  in_missile[0] = position_x using 10^8 decimals
  in_missile[1] = position_y using 10^8 decimals
  in_missile[2] = vector_x using 10^8 decimals
  in_missile[3] = vector_y using 10^8 decimals
  in_missile[4] = radius using 10^8 decimals

The calculation is a simple addition of the x vector with the x position and the 
y vector with the y position.

The missile is shot from position (0, windowWidthScaled) and x vector is always positive
and y vector is always negative. If the missile reaches the edge of the screen it
will either be in the X direction at windowWidthScaled or in the Y direction at 0.

If the missile reaches the edge of the screen in either direction it will be removed 
and the radius is reduced to 0.

For the purpose of legibility, the y value is stored as a positve, but treated as a negative.

*/

template CalculateMissile() {
  Missile input in_missile;
  // log("in_missile[0]", in_missile[0]);
  // log("in_missile[1]", in_missile[1]);
  // log("in_missile[2]", in_missile[2]);
  // log("in_missile[3]", in_missile[3]);
  // log("in_missile[4]", in_missile[4]);
  Missile output out_missile;


  // NOTE: scalingFactorFactor appears in calculateForce, forceAccumulator as well
  var scalingFactorFactor = 3; // maxBits: 2
  var scalingFactor = 10**scalingFactorFactor; // maxBits: 10 (maxNum: 1_000)


  // NOTE: windowWidthScaled appears in forceAccumulator, calculateForce as well and needs to match
  var windowWidth = 1000; // maxBits: 10
  var windowWidthScaled = windowWidth * scalingFactor; // maxBits: 20 (maxNum: 1_000_000)

  // ensure missiles are not faster than limit of 15
  var time = 2;
  var maxMissileVector = time * 15; // maxBits: 5
  var maxMissileVectorScaled = maxMissileVector * scalingFactor; // maxBits: 15 (maxNum: 30_000)
  var missileLimit = 42426; // 30_000√2 ~= 42,426 // maxBits: 16
  // var missileLimit = 21213 // 15_000√2 ~= 21,213 // maxBits: 15
  // vx is always positive
  // vy is always negative
  // the sum of the absolute values of vx and vy must be less than missileLimit
  // according to the triangle inequality threorem that limits the magnitude of the vector
  signal mustBeLessThanMissileLimit <== in_missile.velocity.x + in_missile.velocity.y;
  // log("in_missile[2]", in_missile[2]);
  // log("in_missile[3]", in_missile[3]);
  // log("mustBeLessThanMissileLimit", mustBeLessThanMissileLimit);
  // log("missileLimit", missileLimit);
  component lessThanMissileLimit = LessEqThan(16);
  lessThanMissileLimit.in[0] <== mustBeLessThanMissileLimit;
  lessThanMissileLimit.in[1] <== missileLimit;
  lessThanMissileLimit.out === 1;


  // ensure y is negative
  component isYNegative = LessEqThan(165);
  isYNegative.in[0] <== in_missile.velocity.y;
  isYNegative.in[1] <== maxMissileVectorScaled;
  isYNegative.out === 1;

  // ensure x is positive
  component isXPositive = LessEqThan(15);
  isXPositive.in[0] <== in_missile.velocity.x;
  isXPositive.in[1] <== maxMissileVectorScaled;
  isXPositive.out === 1;


  Vector new_pos;
   // position_x + vector_x
  new_pos.x <== in_missile.position.x + in_missile.velocity.x; // maxBits: 20 (maxNum: 1_030_000)
   // position_y - vector_y (NOTE: vector y is stored as a positive but treated as a negative)
  new_pos.y <== in_missile.position.y - in_missile.velocity.y; // maxBits: 20 (maxNum: 1_030_000)


  // log("new_pos[0]", new_pos[0]);
  // log("new_pos[1]", new_pos[1]);
  // position X is only going to increase from 0 to windowWidthScaled
  // it needs to be kept less than windowWidthScaled
  // can return 0 if it exceeds and use this information to remove the missile
  // log("positionLimiterX in", new_pos[0] + maxMissileVectorScaled);
  // log("positionLimiterX limit", windowWidthScaled + maxMissileVectorScaled);
  component calcMissilePositionLimiterX = Limiter(20);
  calcMissilePositionLimiterX.in <== new_pos.x; // maxBits: 20 (maxNum: 1_030_000)
  calcMissilePositionLimiterX.limit <== windowWidthScaled; // maxBits: 20 (maxNum: 1_030_000)
  calcMissilePositionLimiterX.rather <== 0;
  // log("positionLimiterX out", calcMissilePositionLimiterX.out);

  // This is for the radius of the missile
  // If it went off screen in the x direction the radius should go to 0
  // if not then we want to use the real radius until it's checked
  // on the y dimension
  component calcMissileIsZeroX = IsZero();
  calcMissileIsZeroX.in <== calcMissilePositionLimiterX.out;
  component muxXDecidesRadius = Mux1();
  muxXDecidesRadius.c[0] <== in_missile.radius;
  muxXDecidesRadius.c[1] <== 0;
  muxXDecidesRadius.s <== calcMissileIsZeroX.out;

  // Since the plane goes from 0 to windowWidthScaled on the y axis from top to bottom
  // the missile will approach 0 after starting at windowWidthScaled
  // check whether it goes below 0 by using the maxMissileVectorScaled as a buffer
  // return 0 if it is below maxMissileVectorScaled to remove the missile
  // NOTE: this assumes a missile removal at less than or equal to 0
  // the JS also is <= 0 and not just < 0 for the missile removal

  // log("new_pos[1]", new_pos[1]);
  // log("positionLowerLimiterY in", new_pos[1]);
  // log("positionLowerLimiterY limit", maxMissileVectorScaled);
  // also check the general overboard logic. Would be an edge case but possible.
  component positionLowerLimiterY = LowerLimiter(20); // TODO: confirm type matches bit limit
  positionLowerLimiterY.in <== new_pos.y + maxMissileVectorScaled; // maxBits: 20 (maxNum: 1_030_000)
  positionLowerLimiterY.limit <== maxMissileVectorScaled; // maxBits: 15 (maxNum: 30_000)
  positionLowerLimiterY.rather <== 0;
  // log("positionLowerLimiterY out", positionLowerLimiterY.out);

  component isZeroY = IsZero();
  isZeroY.in <== positionLowerLimiterY.out;
  component muxY = Mux1();
  muxY.c[0] <== muxXDecidesRadius.out;
  muxY.c[1] <== 0;
  muxY.s <== isZeroY.out;

  out_missile.position.x <== new_pos.x; // maxBits: 20 (maxNum: 1_000_000)
  out_missile.position.x.maxvalue = windowWidthScaled;
  out_missile.position.y <== new_pos.y; // maxBits: 20 (maxNum: 1_000_000)
  out_missile.position.y.maxvalue = windowWidthScaled;
  out_missile.velocity.x <== in_missile.velocity.x; // maxBits: 15 (maxNum: 30_000)
  out_missile.velocity.x.maxvalue = maxMissileVectorScaled;
  out_missile.velocity.y <== in_missile.velocity.y; // maxBits: 15 (maxNum: 30_000)
  out_missile.velocity.y.maxvalue = maxMissileVectorScaled;
  out_missile.radius <== muxY.out;
  out_missile.radius.maxvalue = missileLimit;

  // log("out_missile[0]", out_missile[0]);
  // log("out_missile[1]", out_missile[1]);
  // log("out_missile[2]", out_missile[2]);
  // log("out_missile[3]", out_missile[3]);
  // log("out_missile[4]", out_missile[4]);
}