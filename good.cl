class Helper {
  value : Int <- 7;
  text : String <- "cool";
  flag : Bool <- false;

  id(x : Int) : Int {
    x
  };

  ping() : Int {
    0
  };
};

class Base inherits Helper {
  attrOnly : Int;
  attrInit : Int <- 1 + 2 * 3;

  sum(a : Int, b : Int, c : Int) : Int {
    a + b + c
  };

  choose(v : Int) : Int {
    if v < 10 then v else v - 1 fi
  };
};

class Main inherits Base {
  main() : Int {
    {
      attrOnly <- 0;
      ping();
      self@Base.sum(1, 2, 3);
      choose((1 + 2) * 3);
      while attrOnly < 3 loop attrOnly <- attrOnly + 1 pool;
      let x : Int <- 1,
          y : Int <- 2,
          z : Int
      in {
        x <- x + y;
        x;
      };
      case new Helper of
        h : Helper => h.id(5);
        b : Base => b.choose(4);
      esac;
      isvoid new Helper;
      ~1;
      not false;
      "done";
      value = 7;
      attrOnly <= 10;
      attrOnly / 2;
      true;
      attrOnly;
    }
  };
};
