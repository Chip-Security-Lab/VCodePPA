//SystemVerilog
module rotate_carry #(parameter W=8) (
    input  wire              clk,
    input  wire              dir,
    input  wire [W-1:0]      din,
    output reg  [W-1:0]      dout,
    output wire              carry
);

// High-fanout input buffer for din
reg [W-1:0] din_buffered_stage1;
reg [W-1:0] din_buffered_stage2;

always @(posedge clk) begin
    din_buffered_stage1 <= din;
end

always @(posedge clk) begin
    din_buffered_stage2 <= din_buffered_stage1;
end

// Stage 1: Latch input and perform rotation with carry extraction using buffered din
reg [W-1:0] dout_stage1;
reg         carry_bit_stage1;

always @(posedge clk) begin
    if (dir) begin
        // Left rotate
        dout_stage1      <= {din_buffered_stage2[W-2:0], din_buffered_stage2[W-1]};
        carry_bit_stage1 <= din_buffered_stage2[W-1];
    end else begin
        // Right rotate
        dout_stage1      <= {din_buffered_stage2[0], din_buffered_stage2[W-1:1]};
        carry_bit_stage1 <= din_buffered_stage2[0];
    end
end

// Buffer for high-fanout dout_stage1
reg [W-1:0] dout_stage1_buffered;

always @(posedge clk) begin
    dout_stage1_buffered <= dout_stage1;
end

// Stage 2: Output register using buffered dout_stage1
reg [W-1:0] dout_stage2;
reg         carry_bit_stage2;

always @(posedge clk) begin
    dout_stage2      <= dout_stage1_buffered;
    carry_bit_stage2 <= carry_bit_stage1;
end

// Output assignments
always @(posedge clk) begin
    dout <= dout_stage2;
end

assign carry = carry_bit_stage2;

endmodule