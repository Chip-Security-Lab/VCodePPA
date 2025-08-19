module hybrid_timing_shifter (
    input clk, en,
    input [7:0] din,
    input [2:0] shift,
    output [7:0] dout
);
reg [7:0] reg_stage;
wire [7:0] comb_stage = reg_stage << shift;

always @(posedge clk) if(en) reg_stage <= din;

assign dout = en ? comb_stage : reg_stage;
endmodule