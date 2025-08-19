//SystemVerilog
module CaseMux #(parameter N=4, DW=8) (
    input  wire [$clog2(N)-1:0] sel,
    input  wire [N-1:0][DW-1:0] din,
    output reg  [DW-1:0] dout
);
    always @* begin
        if (sel == 0)
            dout = din[0];
        else if (sel == 1)
            dout = din[1];
        else if (sel == 2)
            dout = din[2];
        else if (sel == 3)
            dout = din[3];
        else
            dout = {DW{1'bx}};
    end
endmodule