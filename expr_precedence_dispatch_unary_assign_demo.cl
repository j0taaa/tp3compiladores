class Helper {
  value() : Int {
    1
  };
};

class Main inherits Helper {
  main() : Int {
    let x : Int <- 0 in {
      x <- ~1 + 2 * 3;
      not isvoid new Helper;
      self@Helper.value();
      value();
      x;
    }
  };
};
