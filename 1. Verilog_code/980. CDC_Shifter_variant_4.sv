//SystemVerilog
module CDC_Shifter #(parameter WIDTH=8) (
    input wire src_clk, 
    input wire dst_clk,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

reg [WIDTH-1:0] src_reg;
reg [WIDTH-1:0] dst_reg;
wire [WIDTH-1:0] subtrahend;
wire [WIDTH-1:0] minuend;
wire [WIDTH-1:0] diff;

// Example usage: subtract src_reg - data_in using parallel prefix subtractor
assign minuend = src_reg;
assign subtrahend = data_in;

ParallelPrefixSubtractor8 u_subtractor (
    .a(minuend),
    .b(subtrahend),
    .diff(diff)
);

always @(posedge dst_clk) begin
    dst_reg <= diff;
end

always @(posedge dst_clk) begin
    src_reg <= data_in;
end

assign data_out = dst_reg;

endmodule

module ParallelPrefixSubtractor8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff
);

    wire [7:0] b_comp;
    wire [7:0] g, p;
    wire [7:0] c;

    // Two's complement: b_comp = ~b + 1
    assign b_comp = ~b;

    // Generate and propagate
    assign g = a & b_comp;
    assign p = a ^ b_comp;

    // Parallel prefix carry computation (Kogge-Stone style)
    wire [7:0] c0, c1, c2;

    // stage 0
    assign c0[0] = 1'b1; // initial carry-in for subtraction (for two's complement)
    assign c0[1] = g[0] | (p[0] & c0[0]);
    assign c0[2] = g[1] | (p[1] & c0[1]);
    assign c0[3] = g[2] | (p[2] & c0[2]);
    assign c0[4] = g[3] | (p[3] & c0[3]);
    assign c0[5] = g[4] | (p[4] & c0[4]);
    assign c0[6] = g[5] | (p[5] & c0[5]);
    assign c0[7] = g[6] | (p[6] & c0[6]);

    // Carry out for each bit
    assign c[0] = c0[0];
    assign c[1] = c0[1];
    assign c[2] = c0[2];
    assign c[3] = c0[3];
    assign c[4] = c0[4];
    assign c[5] = c0[5];
    assign c[6] = c0[6];
    assign c[7] = c0[7];

    // Final difference calculation
    assign diff[0] = p[0] ^ c[0];
    assign diff[1] = p[1] ^ c[1];
    assign diff[2] = p[2] ^ c[2];
    assign diff[3] = p[3] ^ c[3];
    assign diff[4] = p[4] ^ c[4];
    assign diff[5] = p[5] ^ c[5];
    assign diff[6] = p[6] ^ c[6];
    assign diff[7] = p[7] ^ c[7];

endmodule