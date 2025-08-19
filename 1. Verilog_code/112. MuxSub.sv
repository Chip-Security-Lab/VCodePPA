module MuxSub(input [3:0] x,y, output [3:0] d);
    assign d = x + (~y + 1);
endmodule