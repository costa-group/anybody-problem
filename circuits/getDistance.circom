pragma circom 2.1.6;

include "approxMath.circom";
include "helpers.circom";
include "buses.circom";

template GetDistance(n) {
  Vector input v1, v2; // maxBits: 20 (maxNum: 1_000_000) = windowWidthScaled
  var scalingFactorFactor = 3;
  var scalingFactor = 10 ** scalingFactorFactor;
  var windowWidth = 1000;
  var windowWidthScaled = windowWidth * scalingFactor;
  var positionMax = windowWidthScaled;
  signal output {maxvalue} distance;

  // signal dx <== x2 - x1;
  component absoluteValueSubtraction = AbsoluteValueSubtraction(n);
  assert(v1.x.maxvalue == windowWidthScaled);
  absoluteValueSubtraction.in[0] <== v1.x; // maxBits: 20 (maxNum: 1_000_000) = windowWidthScaled
  assert(v2.x.maxvalue == windowWidthScaled);
  absoluteValueSubtraction.in[1] <== v2.x; // maxBits: 20 (maxNum: 1_000_000) = windowWidthScaled
  signal dxAbs <== absoluteValueSubtraction.out; // maxBits: 20 (maxNum: 1_000_000) = windowWidthScaled

  // signal dy <== y2 - y1;
  component absoluteValueSubtraction2 = AbsoluteValueSubtraction(n);
  assert(v1.y.maxvalue == windowWidthScaled);
  absoluteValueSubtraction2.in[0] <== v1.y; // maxBits: 20 (maxNum: 1_000_000) = windowWidthScaled
  assert(v2.y.maxvalue == windowWidthScaled);
  absoluteValueSubtraction2.in[1] <== v2.y; // maxBits: 20 (maxNum: 1_000_000) = windowWidthScaled
  signal dyAbs <== absoluteValueSubtraction2.out; // maxBits: 20 (maxNum: 1_000_000) = windowWidthScaled

  signal dxs <== dxAbs * dxAbs; // maxBits: 40 = 20 * 2 (maxNum: 1_000_000_000_000)
  var dxsMax = positionMax ** 2;
  signal dys <== dyAbs * dyAbs; // maxBits: 40 = 20 * 2 (maxNum: 1_000_000_000_000)
  signal distanceSquared <== dxs + dys; // maxBits: 41 = 40 + 1 (maxNum: 2_000_000_000_000)
  var distanceSquaredMax = dxsMax + dxsMax;
//  log("dys", dys);
//  log("dxs", dxs);
//  log("distanceSquared", distanceSquared);
//  log("distanceSquaredMax", distanceSquaredMax);
  component sqrt = Sqrt(distanceSquaredMax);
  sqrt.squaredValue <== distanceSquared;
  distance <== sqrt.root;
  distance.maxvalue = 1414214;

  // // NOTE: confirm this is correct
  // distance <-- approxSqrt(distanceSquared); // maxBits: 21 (maxNum: 1_414_214) ~= 41 / 2 + 2
  // component acceptableMarginOfError = AcceptableMarginOfError((2 * n) + 1);
  // acceptableMarginOfError.expected <== distance ** 2; // maxBits: 41 (maxNum: 2_000_001_237_796) ~= 21 * 2
  // acceptableMarginOfError.actual <== distanceSquared; // maxBits: 41
  // // margin of error should be midpoint between squares
  // acceptableMarginOfError.marginOfError <== distance * 2; // maxBits: 22 (maxNum: 2_828_428)
  // acceptableMarginOfError.out === 1;
}