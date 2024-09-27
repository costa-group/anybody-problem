pragma circom 2.1.6;

include "buses.circom";

function getX(body) {
  return body.position.x;
}
function getY(body) {
  return body.position.y;
}
function getVx(body) {
  return body.velocity.x;
}
function getVy(body) {
  return body.velocity.y;
}
function getMass(body) {
  return body.mass;
}

function maxBits(n) {
  var i = 0;
   while(n > 0) {
    i++;
    n = n >> 1;
   }
   return i;
}
function getBiggest(options, len) {
  var biggest = 0;
  for (var i = 0; i < len; i++) {
    if (options[i] > biggest) {
      biggest = options[i];
    }
  }
  return biggest;
}