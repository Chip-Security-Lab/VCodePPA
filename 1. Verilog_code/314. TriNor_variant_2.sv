//SystemVerilog
module TriNor(input en, a, b, output y);
    assign y = (en & ~a & ~b) ? 1'b1 : (en ? 1'b0 : 1'bz);
endmodule