pragma circom 2.1.6;

include "limiter.circom";

component main { public [ in, limit, rather ]} = Limiter(252);