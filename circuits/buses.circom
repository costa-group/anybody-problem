pragma circom 2.1.6;

bus Vector {
  signal {maxvalue} x, y;
}

bus Body {
  Vector position, velocity;
  signal {maxvalue} mass;
}

bus BodyReduced {
    signal {maxvalue} x, y, radius;
}

bus Force {
  signal {maxvalue} x_unsigned, y_unsigned;
  signal {binary} sign_x, sign_y;
}

bus Missile {
  Vector position, velocity;
  signal {maxvalue} radius;
}

bus MissileReduced {
    signal {maxvalue} x, y, radius;
}