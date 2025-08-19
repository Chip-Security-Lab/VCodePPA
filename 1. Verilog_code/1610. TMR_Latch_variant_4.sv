//SystemVerilog
module TMR_Latch #(parameter DW=8) (
    input clk,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

// Buffer registers for high fanout input
reg [DW-1:0] din_buf1, din_buf2;
reg [DW-1:0] reg1, reg2, reg3;
reg [DW-1:0] voter_stage1, voter_stage2;

// First stage buffer
always @(posedge clk) din_buf1 <= din;
always @(posedge clk) din_buf2 <= din_buf1;

// Main TMR registers
always @(posedge clk) reg1 <= din_buf2;
always @(posedge clk) reg2 <= din_buf2;
always @(posedge clk) reg3 <= din_buf2;

// Pipelined majority voter
reg [DW-1:0] reg1_reg2, reg2_reg3, reg1_reg3;
always @(posedge clk) begin
    reg1_reg2 <= reg1 & reg2;
    reg2_reg3 <= reg2 & reg3;
    reg1_reg3 <= reg1 & reg3;
end

// Final OR stage
assign dout = reg1_reg2 | reg2_reg3 | reg1_reg3;

endmodule