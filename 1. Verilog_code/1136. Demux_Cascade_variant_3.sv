//SystemVerilog
// Top-level module
module Demux_Cascade #(
    parameter DW = 8,    // Data width
    parameter DEPTH = 2  // Cascade depth
) (
    input clk,
    input [DW-1:0] data_in,
    input [$clog2(DEPTH+1)-1:0] addr,
    output [DEPTH:0][DW-1:0] data_out
);
    // Internal wires for cascading
    wire [DEPTH:0][DW-1:0] stage_outputs;
    
    // First stage demux
    Demux_Stage #(
        .DW(DW),
        .STAGE_ID(0)
    ) first_stage (
        .clk(clk),
        .data_in(data_in),
        .addr(addr),
        .prev_stage_out({DW{1'b0}}),
        .stage_out(stage_outputs[0])
    );
    
    // Generate cascaded demux stages
    genvar i;
    generate
        for (i = 1; i <= DEPTH; i = i + 1) begin : demux_stages
            Demux_Stage #(
                .DW(DW),
                .STAGE_ID(i)
            ) stage (
                .clk(clk),
                .data_in(data_in),
                .addr(addr),
                .prev_stage_out(stage_outputs[i-1]),
                .stage_out(stage_outputs[i])
            );
        end
    endgenerate
    
    // Connect stage outputs to module outputs
    assign data_out = stage_outputs;
    
endmodule

// Single stage demux module
module Demux_Stage #(
    parameter DW = 8,           // Data width
    parameter STAGE_ID = 0      // Stage identifier
) (
    input clk,
    input [DW-1:0] data_in,
    input [$clog2(STAGE_ID+2)-1:0] addr,
    input [DW-1:0] prev_stage_out,
    output [DW-1:0] stage_out
);
    // Address decoder and output selection logic using conditional sum subtractor
    Address_Decoder #(
        .DW(DW),
        .ADDR_MATCH(STAGE_ID)
    ) addr_decoder (
        .clk(clk),
        .data_in(data_in),
        .prev_data(prev_stage_out),
        .addr(addr),
        .data_out(stage_out)
    );
    
endmodule

// Address decoder module with conditional sum subtractor
module Address_Decoder #(
    parameter DW = 8,           // Data width
    parameter ADDR_MATCH = 0    // Address to match
) (
    input clk,
    input [DW-1:0] data_in,
    input [DW-1:0] prev_data,
    input [$clog2(ADDR_MATCH+2)-1:0] addr,
    output reg [DW-1:0] data_out
);
    // Internal signals for conditional sum subtraction
    wire [DW-1:0] addr_diff;
    wire [DW-1:0] cond_sum_result;
    wire addr_match;
    
    // Conditional Sum Subtractor implementation
    // Generate condition for subtraction
    // Calculate addr - ADDR_MATCH
    Conditional_Sum_Subtractor #(
        .WIDTH(DW)
    ) addr_subtractor (
        .a({DW{1'b0}} + addr),
        .b({DW{1'b0}} + ADDR_MATCH),
        .diff(addr_diff)
    );
    
    // Check if address matches
    assign addr_match = (addr_diff == {DW{1'b0}});
    
    // Select appropriate output based on address match
    always @(posedge clk) begin
        if (addr_match)
            data_out <= data_in;
        else
            data_out <= prev_data;
    end
    
endmodule

// Conditional Sum Subtractor module
module Conditional_Sum_Subtractor #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    // Internal signals
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff_0, diff_1;
    wire [WIDTH-1:0] sel;
    
    // Initialize borrow-in for LSB
    assign borrow[0] = 1'b0;
    
    // Generate both possible results for each bit position
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            // Calculate results for both borrow scenarios
            assign diff_0[i] = a[i] ^ b[i] ^ 1'b0;  // No borrow in
            assign diff_1[i] = a[i] ^ b[i] ^ 1'b1;  // With borrow in
            
            // Calculate borrow propagation
            assign borrow[i+1] = (b[i] & ~a[i]) | ((b[i] | ~a[i]) & borrow[i]);
            
            // Select the correct result based on actual borrow
            assign sel[i] = borrow[i];
            assign diff[i] = sel[i] ? diff_1[i] : diff_0[i];
        end
    endgenerate
    
endmodule