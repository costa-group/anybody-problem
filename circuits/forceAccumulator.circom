pragma circom 2.1.6;

include "limiter.circom";
include "calculateForce.circom";
include "helpers.circom";
include "buses.circom";

// TODO:
// √ confirm why circom interprets negative input differently than p-n (https://github.com/0xPARC/zkrepl/issues/11)
// √ go through and make sure approximate square root is working ok
// √ go through and make sure that decimals of 10^8 are properly accounted for in exponential equations
// √ change js implementation to use square root approx function
// analyze risk here: initial thought is that valid proofs can be generated for slight variations of position. seems acceptable.
// use inverse square root instead of division
// √ make change input array variable of n
// √ make change in body variable of n
  // make sure max n is used to bound the number of bits
// generate and test prover for step of 1
// configure as recursive proof, generate and test prover for step of n
// define "types" for all the values and make sure they're within the acceptable ranges attached to those types.
  // This will help us restrict bits needed for each type
  // maybe can streamline the square root and division


// TODO: clean up this file it's a mess

template ForceAccumulator(totalBodies) { // max 10 = maxBits: 4
    Body input bodies[totalBodies];
    Body output out_bodies[totalBodies];
    // [0] = position_x       | maxBits: 20 = windowWidthScaled (maxNum: 1_000_000)
    // [1] = position_y       | maxBits: 20 = windowWidthScaled (maxNum: 1_000_000)
    // [2] = vector_x         | maxBits: 16 (maxNum: 40_000) = 2 * maxVector (maxVector offset by +maxVector so num is never negative)
    // [3] = vector_y         | maxBits: 16 (maxNum: 40_000) = 2 * maxVector (maxVector offset by +maxVector so num is never negative)
    // [4] = radius           | maxBits: 14 = numBits(13 * scalingFactor) (maxNum: 13_000)

    // NOTE: scalingFactorFactor appears in calculateMissile, calculateForce as well
    var scalingFactorFactor = 3; // maxBits: 2
    var scalingFactor = 10**scalingFactorFactor; // maxBits: 10 (maxNum: 1_000)

    var time = 2; // maxBits: 2
    var maxVector = 10 * time; // maxBits: 5
    var maxVectorScaled = maxVector * scalingFactor; // maxBits: 15 (maxNum: 20_000)

    // NOTE: windowWidth appears in calculateMissile, calculateForce, forceAccumulator as well and needs to match
    var windowWidth = 1000; // maxBits: 10
    var windowWidthScaled = windowWidth * scalingFactor; // maxBits: 20 (maxNum: 1_000_000)

    var accumulated_body_forces[totalBodies][2];
    var totalIterations = totalBodies * (totalBodies - 1) / 2; // maxBits: 6 (maxNum: 45)
    component calculateForceComponent[totalIterations];
    // signal force_x[totalIterations][2]; // maxBits: 64 (maxNum: 10_400_000_000_000_000_000) = out_forces max, unsigned
    // signal force_y[totalIterations][2]; // maxBits: 64 (maxNum: 10_400_000_000_000_000_000) = out_forces max, unsigned
    Force force;

    component mux[totalIterations * 2];
    var ii = 0;
    // NOTE: Below we're setting initial values for accumulate_body_forces to be the
    // maximum accumulated value possible (maximum value for force multiplied by 
    // totalIterations). This is an offset to avoid going into negative numbers so that
    // comparators later on will not need to cover the full range of the prime field.
    // Maximum accumulated value must be removed before final value is returned.
    var maximum_accumulated_possible = 468000000000000000000; // maxBits: 69 (maxNum: 468_000_000_000_000_000_000) = out_forces * totalIterations
    for (var i = 0; i < totalBodies; i++) {
      assert(bodies[i].position.x.maxvalue == windowWidthScaled);
      assert(bodies[i].position.y.maxvalue == windowWidthScaled);
      assert(bodies[i].velocity.x.maxvalue == windowWidthScaled);
      assert(bodies[i].velocity.y.maxvalue == windowWidthScaled);
      assert(bodies[i].mass.maxvalue == 32000);
      accumulated_body_forces[i][0] = maximum_accumulated_possible; // maxBits: 69 (maxNum: 468_000_000_000_000_000_000) = out_forces * totalIterations
      accumulated_body_forces[i][1] = maximum_accumulated_possible; // maxBits: 69 (maxNum: 468_000_000_000_000_000_000) = out_forces * totalIterations
    }
    for (var i = 0; i < totalBodies; i++) {
      // radius of body doesn't change
      out_bodies[i].mass <== bodies[i].mass; // maxBits: 15 (maxNum: 32_000)
      out_bodies[i].mass.maxvalue = 32000;
      for (var j = i+1; j < totalBodies; j++) {
        // calculate the force between i and j
        calculateForceComponent[ii] = CalculateForce();
        calculateForceComponent[ii].in_bodies[0] <== bodies[i];
        calculateForceComponent[ii].in_bodies[1] <== bodies[j];
        force = calculateForceComponent[ii].out_forces; // maxBits: 64 (maxNum: 10_400_000_000_000_000_000)
        // accumulate the value of the force on body i and body j
        // log("in_bodies[0] = ", i);
        // log("in_bodies[1] = ", j);
        // log("force_x[0]", force_x[0]);
        // log("force_x[1]", force_x[1]);
        // log("force_y[0]", force_y[0]);
        // log("force_y[1]", force_y[1]);

        // accumulate the x forces
        mux[ii] = MultiMux1(2);
        mux[ii].c[0][0] <== accumulated_body_forces[i][0] + (time * force.x_unsigned); // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000) = maximum_accumulated_possible + time (2) * maximum_accumulated_possible
        mux[ii].c[0][1] <== accumulated_body_forces[i][0] - (time * force.x_unsigned); // maxBits: 69 (maxNum: 468_000_000_000_000_000_000) = maximum_accumulated_possible
        mux[ii].c[1][0] <== accumulated_body_forces[j][0] - (time * force.x_unsigned); // maxBits: 69 (maxNum: 468_000_000_000_000_000_000)
        mux[ii].c[1][1] <== accumulated_body_forces[j][0] + (time * force.x_unsigned); // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000) = maximum_accumulated_possible + time (2) * maximum_accumulated_possible
        mux[ii].s <== force.sign_x;
        accumulated_body_forces[i][0] = mux[ii].out[0]; // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000)
        accumulated_body_forces[j][0] = mux[ii].out[1]; // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000)

        // accumulate the y forces
        mux[totalIterations + ii] = MultiMux1(2);
        mux[totalIterations + ii].c[0][0] <== accumulated_body_forces[i][1] +  (time * force.y_unsigned); // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000) = maximum_accumulated_possible + time (2) * maximum_accumulated_possible
        mux[totalIterations + ii].c[0][1] <== accumulated_body_forces[i][1] -  (time * force.y_unsigned); // maxBits: 69 (maxNum: 468_000_000_000_000_000_000)
        mux[totalIterations + ii].c[1][0] <== accumulated_body_forces[j][1] -  (time * force.y_unsigned); // maxBits: 69 (maxNum: 468_000_000_000_000_000_000)
        mux[totalIterations + ii].c[1][1] <== accumulated_body_forces[j][1] +  (time * force.y_unsigned); // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000) = maximum_accumulated_possible + time (2) * maximum_accumulated_possible
        mux[totalIterations + ii].s <== force.sign_y;
        accumulated_body_forces[i][1] = mux[totalIterations + ii].out[0]; // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000) = maximum_accumulated_possible + time (2) * maximum_accumulated_possible
        accumulated_body_forces[j][1] = mux[totalIterations + ii].out[1]; // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000) = maximum_accumulated_possible + time (2) * maximum_accumulated_possible

        ii = ii + 1;
      }
    }


    Vector new_vector[totalBodies];
    component vectorLimiterX[totalBodies];
    component vectorLowerLimiterX[totalBodies];
    component vectorLimiterY[totalBodies];
    component vectorLowerLimiterY[totalBodies];
    component positionLimiterX[totalBodies];
    component positionLowerLimiterX[totalBodies];
    component positionLimiterY[totalBodies];
    component positionLowerLimiterY[totalBodies];
    component isZeroX[totalBodies];
    component muxX[totalBodies];
    component isZeroY[totalBodies];
    component muxY[totalBodies];

    for (var i = 0; i < totalBodies; i++) {
      // log("!!!!!!!!!!");
      // log("i-i-i-i-i", i);
      // log("accumulated_body_forces_x", i, accumulated_body_forces[i][0]);
      // log("accumulated_body_forces_y", i, accumulated_body_forces[i][1]);
      // calculate the new vector for body i
      /*
      NOTE: 
      new_vector is a combination of the current vector which is offset by maxVectorScaled
      and the accumulated_body_forces which is offset by maximum_accumulated_possible
      */
      new_vector[i].x <== bodies[i].velocity.x + accumulated_body_forces[i][0]; // maxBits: 71 (maxNum: 1_404_000_000_000_000_040_000) = (2 * maximum_accumulated_possible) + (2 * maxVector)
      new_vector[i].y <== bodies[i].velocity.y + accumulated_body_forces[i][1]; // maxBits: 71 (maxNum: 1_404_000_000_000_000_040_000) = (2 * maximum_accumulated_possible) + (2 * maxVector)
      // log("bodies[i][2]", bodies[i][2]);
      // log("accumulated_body_forces[i][0]", accumulated_body_forces[i][0]);
      // log("new_vector_x[i]", new_vector_x[i]);
      // log("new_vector_y[i]", new_vector_y[i]);
      // limit the magnitude of the vector
      /* 
      NOTE: vectorLimitX needs to be limited by maxVectorScaled. However because new_vector_x
      is already offset by maxVectorScaled and maximum_accumulated_possible, we need to add
      both to the limit and remove maximum_accumulated_possible from the result. The final
      result will still contain the maxVectorScaled offset that will prevent the vector from
      becoming negative.
      */
      vectorLimiterX[i] = Limiter(71);
      // log("new_vector_x", i, new_vector_x[i]);
      // log("new_vector_x[i] + maxVectorScaled", i, new_vector_x[i] + maxVectorScaled);
      // log("limit", "maxVectorScaled + maxVectorScaled + maximum_accumulated_possible", maxVectorScaled + maxVectorScaled + maximum_accumulated_possible);
      // log("rather", "maxVectorScaled + maxVectorScaled + maximum_accumulated_possible", maxVectorScaled + maxVectorScaled + maximum_accumulated_possible);
      vectorLimiterX[i].in <== new_vector[i].x; // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000)
      vectorLimiterX[i].limit <== 2 * maxVectorScaled + maximum_accumulated_possible; // maxBits: 69 (maxNum: 468_000_000_000_000_040_000)
      vectorLimiterX[i].rather <== 2 * maxVectorScaled + maximum_accumulated_possible; // maxBits: 69 (maxNum: 468_000_000_000_000_040_000)
      // out_bodies[i][2] <== vectorLimiterX[i].out - maximum_accumulated_possible; // maxBits: 15 (maxNum: 20_000)
      
      // isZero[i]  = IsZero();
      // isZero[i].in <== vectorLimiterX[i].out - (maxVectorScaled * 2);

      // mux[i] = Mux1();
      // mux.c[0] <== vectorLimiterX[i].out - maximum_accumulated_possible;
      // mux.c[1] <== vectorLimiterX[i].out;
      // mux.s <== isZero[i].out;


      // at this point the vector is offset by maxVectorScaled but not maximum_accumulated_possible
      // 

      vectorLowerLimiterX[i] = LowerLimiter(16);
      // log("vectorLimiterX[i].out", i, vectorLimiterX[i].out);
      // log("vectorLimiterX[i].in <==", "vectorLimiterX[i].out - maximum_accumulated_possible", vectorLimiterX[i].out - maximum_accumulated_possible + maxVectorScaled);
      // log("maxVectorScaled.limit", "maxVectorScaled", maxVectorScaled);
      // log("maxVectorScaled.rather", "maxVectorScaled", maxVectorScaled);
      vectorLowerLimiterX[i].in <== vectorLimiterX[i].out - maximum_accumulated_possible + maxVectorScaled; // maxBits: 16 (maxNum: 40_000)
      vectorLowerLimiterX[i].limit <== maxVectorScaled; // maxBits: 13 (maxNum: 10_000)
      vectorLowerLimiterX[i].rather <== maxVectorScaled; // maxBits: 13 (maxNum: 10_000)
      // log("vectorLowerLimiterX[i].out", vectorLowerLimiterX[i].out);
      // log("out_bodies[i][3]", "vectorLowerLimiterX[i].out - maxVectorScaled", vectorLowerLimiterX[i].out - maxVectorScaled);
      out_bodies[i].velocity.x <== vectorLowerLimiterX[i].out - maxVectorScaled; // maxBits: 15 (maxNum: 20_000)
      out_bodies[i].velocity.x.maxvalue = maxVectorScaled;

      // NOTE: same as above
      vectorLimiterY[i] = Limiter(71);
      // log("new_vector_y", i, new_vector_y[i]);
      // log("new_vector_y[i] + maxVectorScaled", i, new_vector_y[i] + maxVectorScaled);
      // log("limit", "maxVectorScaled + maxVectorScaled + maximum_accumulated_possible", maxVectorScaled + maxVectorScaled + maximum_accumulated_possible);
      // log("rather", "maxVectorScaled + maxVectorScaled + maximum_accumulated_possible", maxVectorScaled + maxVectorScaled + maximum_accumulated_possible);
      vectorLimiterY[i].in <== new_vector[i].y; // maxBits: 71 (maxNum: 1_404_000_000_000_000_000_000)
      vectorLimiterY[i].limit <== 2 * maxVectorScaled + maximum_accumulated_possible; // maxBits: 69 (maxNum: 468_000_000_000_000_020_000)
      vectorLimiterY[i].rather <== 2 * maxVectorScaled + maximum_accumulated_possible; // maxBits: 69 (maxNum: 468_000_000_000_000_020_000)
      // out_bodies[i][3] <== vectorLimiterY[i].out - maximum_accumulated_possible; // maxBits: 15 (maxNum: 20_000)

      vectorLowerLimiterY[i] = LowerLimiter(16);
      // log("vectorLimiterY[i].out", i, vectorLimiterY[i].out);
      // log("vectorLimiterY[i].in", "vectorLimiterY[i].out - maximum_accumulated_possible", vectorLimiterY[i].out - maximum_accumulated_possible);
      // log("maxVectorScaled.limit", "maxVectorScaled", maxVectorScaled);
      // log("maxVectorScaled.rather", "maxVectorScaled", maxVectorScaled);
      vectorLowerLimiterY[i].in <== vectorLimiterY[i].out - maximum_accumulated_possible + maxVectorScaled; // maxBits: 16 (maxNum: 40_000 = 468_000_000_000_000_020_000 - 468_000_000_000_000_000_000 + 20_000)
      vectorLowerLimiterY[i].limit <== maxVectorScaled; // maxBits: 15 (maxNum: 20_000)
      vectorLowerLimiterY[i].rather <== maxVectorScaled; // maxBits: 15 (maxNum: 20_000)
      // log("vectorLowerLimiterY[i].out", vectorLowerLimiterY[i].out);
      // log("out_bodies[i][3]", "vectorLowerLimiterY[i].out - maxVectorScaled", vectorLowerLimiterY[i].out - maxVectorScaled);
      out_bodies[i].velocity.y <== vectorLowerLimiterY[i].out - maxVectorScaled; // maxBits: 15 (maxNum: 20_000)
      out_bodies[i].velocity.y.maxvalue = maxVectorScaled;


      // need to limit position so plane loops off edges
      /*
      NOTE: vectors are already offset with maxVectorScaled so that they are never negative.
      When calculating the change in position, we need to subtract maxVectorScaled to ensure
      that negative values are handled properly. However, we also want to prevent the position
      from becoming a negative value and requiring 254 bits to represent. To do this, we add
      maxVectorScaled to the position before limiting it. That is why we have the otherwise
      nonsensical calculation below where we add then remove maxVectorScaled.

      +bodies[i][0] is the actual position of the body (maxNum: 1_000_000)
      +out_bodies[i][2] is the x vector of the body with an additional maxVectorScaled offset (maxNum: 20_000)
      -maxVectorScaled has to be removed to account for the vector offset (maxNum: 20_000)
      +maxVectorScaled is added to ensure that the position is never negative (maxNum: 20_000)

      maxVectorScaled will need to be removed from the final position value
      */
      positionLimiterX[i] = Limiter(20);
      positionLimiterX[i].in <== bodies[i].position.x + out_bodies[i].velocity.x; // maxBits: 20 (maxNum: 1_020_000)
      positionLimiterX[i].limit <== windowWidthScaled + maxVectorScaled; // maxBits: 20 (maxNum: 1_020_000)
      positionLimiterX[i].rather <== maxVectorScaled; // maxBits: 15 (maxNum: 20_000)

      // NOTE: maxVectorScaled is still included, needs to be removed at end of lowerLimiter
      positionLowerLimiterX[i] = LowerLimiter(20);
      positionLowerLimiterX[i].in <== bodies[i].position.x + out_bodies[i].velocity.x; // maxBits: 20 (maxNum: 1_040_000)
      positionLowerLimiterX[i].limit <== maxVectorScaled; // maxBits: 15 (maxNum: 20_000)
      positionLowerLimiterX[i].rather <== windowWidthScaled + maxVectorScaled; // maxBits: 20 (maxNum: 1_020_000)
      // out_bodies[i][0] <== positionLowerLimiterX[i].out;
    
      isZeroX[i]  = IsZero();
      isZeroX[i].in <== positionLimiterX[i].in - positionLimiterX[i].out;
      // log("bodies[i][0]", bodies[i][0]);
      // log("out_bodies[i][2]", out_bodies[i][2]);
      // log("bodies[i][0] + out_bodies[i][2]", bodies[i][0] + out_bodies[i][2]);
      // log("positionLimiterX[i].in", positionLimiterX[i].in);
      // log("positionLimiterX[i].out", positionLimiterX[i].out);


      // log("positionLowerLimiterX[i].in", positionLowerLimiterX[i].in);
      // log("positionLowerLimiterX[i].out", positionLowerLimiterX[i].out);
      // log("positionLowerLimiterX[i].out - maxVectorScaled", positionLowerLimiterX[i].out - maxVectorScaled);

      // log("isZeroX[i].out", isZeroX[i].out);
      muxX[i] = Mux1();
      muxX[i].c[0] <== positionLimiterX[i].out - maxVectorScaled;
      muxX[i].c[1] <== positionLowerLimiterX[i].out - maxVectorScaled;
      muxX[i].s <== isZeroX[i].out;
  
      // if positionLimiterX.out !== positionLimiterX.in, then out_bodies[i][0] <== positionLimiterX.out
      // else, out_bodies[i][0] <== positionLowerLimiterX.out
      out_bodies[i].position.x <== muxX[i].out;
      out_bodies[i].position.x.maxvalue = windowWidthScaled;
  


      // NOTE: same as above
      positionLimiterY[i] = Limiter(20);
      positionLimiterY[i].in <== bodies[i].position.y + out_bodies[i].velocity.y; // maxBits: 20 (maxNum: 1_020_000)
      positionLimiterY[i].limit <== windowWidthScaled + maxVectorScaled; // maxBits: 20 (maxNum: 1_020_000)
      positionLimiterY[i].rather <== maxVectorScaled; // maxBits: 15 (maxNum: 20_000)

      // NOTE: maxVectorScaled is still included, needs to be removed at end of calculation
      positionLowerLimiterY[i] = LowerLimiter(20);
      positionLowerLimiterY[i].in <== bodies[i].position.y + out_bodies[i].velocity.y; // maxBits: 20 (maxNum: 1_020_000)
      positionLowerLimiterY[i].limit <== maxVectorScaled; // maxBits: 15 (maxNum: 20_000)
      positionLowerLimiterY[i].rather <== windowWidthScaled + maxVectorScaled; // maxBits: 20 (maxNum: 1_020_000)
      // out_bodies[i][1] <== positionLowerLimiterY[i].out;

          
      isZeroY[i]  = IsZero();
      isZeroY[i].in <== positionLimiterY[i].in - positionLimiterY[i].out;

      muxY[i] = Mux1();
      muxY[i].c[0] <== positionLimiterY[i].out - maxVectorScaled;
      muxY[i].c[1] <== positionLowerLimiterY[i].out - maxVectorScaled;
      muxY[i].s <== isZeroY[i].out;
  
      // if positionLimiterX.out !== positionLimiterX.in, then out_bodies[i][0] <== positionLimiterX.out
      // else, out_bodies[i][0] <== positionLowerLimiterX.out
      out_bodies[i].position.y <== muxY[i].out;
      out_bodies[i].position.y.maxvalue = windowWidthScaled;
    }
    // log("out_bodies[0][0]", out_bodies[0][0]);
    // log("out_bodies[0][1]", out_bodies[0][1]);
    // log("out_bodies[0][2]", out_bodies[0][2]);
    // log("out_bodies[0][3]", out_bodies[0][3]);
    // log("out_bodies[0][4]", out_bodies[0][4]);
    // log("out_bodies[1][0]", out_bodies[1][0]);
    // log("out_bodies[1][1]", out_bodies[1][1]);
    // log("out_bodies[1][2]", out_bodies[1][2]);
    // log("out_bodies[1][3]", out_bodies[1][3]);
    // log("out_bodies[1][4]", out_bodies[1][4]);
    // log("out_bodies[2][0]", out_bodies[2][0]);
    // log("out_bodies[2][1]", out_bodies[2][1]);
    // log("out_bodies[2][2]", out_bodies[2][2]);
    // log("out_bodies[2][3]", out_bodies[2][3]);
    // log("out_bodies[2][4]", out_bodies[2][4]);

}


/* INPUT = {
    "bodies": [
      ["22600000000", "4200000000", "-133000000", "-629000000", "10000000000"],
      ["36300000000", "65800000000", "-332000000", "374000000", "7500000000"],
      ["67900000000", "50000000000", "229000000", "252000000", "5000000000"] ]
} */