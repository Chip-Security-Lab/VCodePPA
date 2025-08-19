//SystemVerilog
module RangeDetector_APB #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input psel, penable, pwrite,
    input [ADDR_WIDTH-1:0] paddr,
    input [WIDTH-1:0] pwdata,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] prdata,
    output reg out_range
);

reg [WIDTH-1:0] thresholds[0:1];
wire [WIDTH-1:0] lower_diff, upper_diff;
wire lower_borrow, upper_borrow;

// Parallel Prefix Subtractor for lower bound comparison
ParallelPrefixSubtractor #(.WIDTH(WIDTH)) lower_sub (
    .a(data_in),
    .b(thresholds[0]),
    .diff(lower_diff),
    .borrow(lower_borrow)
);

// Parallel Prefix Subtractor for upper bound comparison
ParallelPrefixSubtractor #(.WIDTH(WIDTH)) upper_sub (
    .a(thresholds[1]),
    .b(data_in),
    .diff(upper_diff),
    .borrow(upper_borrow)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        thresholds[0] <= 0;
        thresholds[1] <= {WIDTH{1'b1}};
    end
    else if(psel && penable && pwrite) begin
        thresholds[paddr] <= pwdata;
    end
end

always @(posedge clk) begin
    out_range <= lower_borrow || upper_borrow;
    prdata <= thresholds[paddr];
end

endmodule

module ParallelPrefixSubtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow
);

wire [WIDTH-1:0] g, p;
wire [WIDTH-1:0] carry;

// Generate and Propagate
genvar i;
generate
    for(i = 0; i < WIDTH; i = i + 1) begin: gen_pp
        assign g[i] = ~a[i] & b[i];
        assign p[i] = a[i] ^ b[i];
    end
endgenerate

// Parallel Prefix Tree
assign carry[0] = 1'b1;
generate
    for(i = 1; i < WIDTH; i = i + 1) begin: gen_carry
        assign carry[i] = g[i-1] | (p[i-1] & carry[i-1]);
    end
endgenerate

// Final Difference
assign diff = p ^ carry;
assign borrow = carry[WIDTH-1];

endmodule