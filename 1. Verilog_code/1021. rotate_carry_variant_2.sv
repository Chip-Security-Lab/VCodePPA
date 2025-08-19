//SystemVerilog
module rotate_carry #(parameter W=8) (
    input clk,
    input dir,
    input [W-1:0] din,
    output [W-1:0] dout,
    output carry
);

// Stage 1: Register inputs
reg [W-1:0] din_stage1;
reg dir_stage1;

always @(posedge clk) begin
    din_stage1 <= din;
    dir_stage1 <= dir;
end

// Stage 2: Partial combination logic and pipelining
reg [W-1:0] din_stage2;
reg dir_stage2;
reg din_lsb_stage2;
reg din_msb_stage2;

always @(posedge clk) begin
    din_stage2 <= din_stage1;
    dir_stage2 <= dir_stage1;
    din_lsb_stage2 <= din_stage1[0];
    din_msb_stage2 <= din_stage1[W-1];
end

// Stage 3: Final combination logic and output registers
reg [W-1:0] dout_stage3;
reg carry_stage3;

wire [W-1:0] rotate_left_stage2;
wire [W-1:0] rotate_right_stage2;

assign rotate_left_stage2  = {din_stage2[W-2:0], din_msb_stage2};
assign rotate_right_stage2 = {din_lsb_stage2, din_stage2[W-1:1]};

always @(posedge clk) begin
    if (dir_stage2) begin
        dout_stage3  <= rotate_left_stage2;
        carry_stage3 <= din_stage2[W-1];
    end else begin
        dout_stage3  <= rotate_right_stage2;
        carry_stage3 <= din_stage2[0];
    end
end

assign dout  = dout_stage3;
assign carry = carry_stage3;

endmodule