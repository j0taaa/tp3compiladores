(* Classe com erro no cabecalho; o parser deve reiniciar na proxima classe. *)
class BrokenClass inherits {
  a : Int <- 0;
};

class RecoverFeatures {
  ok_attr : Int <- 1;
  broken_attr : <- 2;
  ok_method(x : Int) : Int {
    x
  };
  broken_method(x Int) : Int {
    x
  };
  after_errors() : Int {
    0
  };

  broken_let() : Int {
    let a : Int <- 1,
        b : <- 2,
        c : Int <- 3,
        d : String <- "ok"
    in c
  };

  broken_block() : Int {
    {
      1;
      x <-
    }
  };

  broken_block_chain() : Int {
    {
      1;
      y <- ;
      3;
    }
  };

  after_block() : Int {
    1
  };
};

class FinalGood {
  main() : Int {
    {
      1;
      2;
    }
  };
};
