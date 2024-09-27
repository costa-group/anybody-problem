pragma circom 2.1.6;

bus Vector {
  signal x, y;
}

bus Body {
  Vector position, velocity;
  signal mass;
}

bus BodyReduced {
    signal x, y, radius;
}

bus Force {
  signal {maxvalue} x_unsigned, y_unsigned;
  signal {binary} sign_x, sign_y;
}

bus Missile {
  Vector position, velocity;
  signal radius;
}

bus MissileReduced {
    signal x, y, radius;
}