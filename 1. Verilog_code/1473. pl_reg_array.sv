module pl_reg_array #(parameter DW=8, AW=4) (
    input clk, we,
    input [AW-1:0] addr,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
reg [DW-1:0] mem [0:(1<<AW)-1];
always @(posedge clk)
    if (we) mem[addr] <= data_in;
assign data_out = mem[addr];
endmodule