//SystemVerilog
module RangeDetector_SyncEnRst #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    output reg out_flag
);

wire [WIDTH-1:0] lower_diff;
wire [WIDTH-1:0] upper_diff;
wire lower_ge;
wire upper_le;

// 先行借位减法器实现
CarryLookaheadSubtractor #(.WIDTH(WIDTH)) lower_sub (
    .a(data_in),
    .b(lower_bound),
    .diff(lower_diff),
    .borrow_out()
);

CarryLookaheadSubtractor #(.WIDTH(WIDTH)) upper_sub (
    .a(upper_bound),
    .b(data_in),
    .diff(upper_diff),
    .borrow_out()
);

assign lower_ge = ~lower_diff[WIDTH-1];
assign upper_le = ~upper_diff[WIDTH-1];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_flag <= 1'b0;
    else if(en) begin
        out_flag <= lower_ge && upper_le;
    end
end

endmodule

module CarryLookaheadSubtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow_out
);

wire [WIDTH:0] borrow;
wire [WIDTH-1:0] p, g;

assign borrow[0] = 1'b1;

genvar i;
generate
    for(i = 0; i < WIDTH; i = i + 1) begin: sub_bit
        assign p[i] = a[i] ^ b[i];
        assign g[i] = ~a[i] & b[i];
        assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
        assign diff[i] = p[i] ^ borrow[i];
    end
endgenerate

assign borrow_out = borrow[WIDTH];

endmodule