//SystemVerilog
module TMR_Latch #(parameter DW=8) (
    input clk,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] reg1, reg2, reg3;
    always @(posedge clk) reg1 <= din;
    always @(posedge clk) reg2 <= din;
    always @(posedge clk) reg3 <= din;
    assign dout = (reg1 & reg2) | (reg2 & reg3) | (reg1 & reg3);
endmodule