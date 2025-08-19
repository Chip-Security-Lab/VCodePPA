//SystemVerilog
// Top-level module with pipelined data path
module Hier_NAND #(
    parameter WIDTH = 2
)(
    input wire clk,                 // Added clock for pipeline registers
    input wire rst_n,               // Added reset for pipeline registers
    input wire [WIDTH-1:0] a, b,    // Input data buses
    output wire [WIDTH*2-1:0] y     // Output data bus
);
    // Internal pipeline registers
    reg [WIDTH-1:0] a_reg, b_reg;
    reg [WIDTH-1:0] nand_result_reg;
    reg [WIDTH-1:0] fixed_bits_reg;
    
    // Stage 1: Input Capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= {WIDTH{1'b0}};
            b_reg <= {WIDTH{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Stage 2: NAND Operation
    wire [WIDTH-1:0] nand_result;
    NAND_array_optimized #(
        .WIDTH(WIDTH)
    ) nand_logic (
        .a(a_reg),
        .b(b_reg),
        .y(nand_result)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result_reg <= {WIDTH{1'b0}};
        end else begin
            nand_result_reg <= nand_result;
        end
    end
    
    // Stage 3: Fixed Bits Generation
    wire [WIDTH-1:0] fixed_bits;
    FixedBits_optimized #(
        .WIDTH(WIDTH)
    ) fixed_bits_gen (
        .y(fixed_bits)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fixed_bits_reg <= {WIDTH{1'b0}};
        end else begin
            fixed_bits_reg <= fixed_bits;
        end
    end
    
    // Final output composition
    assign y = {fixed_bits_reg, nand_result_reg};
    
endmodule

// Optimized NAND array with balanced logic depth
module NAND_array_optimized #(
    parameter WIDTH = 2
)(
    input wire [WIDTH-1:0] a, b,
    output wire [WIDTH-1:0] y
);
    // Split large operations into smaller balanced trees
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_nand
            NAND_balanced nand_inst (
                .a(a[i]),
                .b(b[i]),
                .y(y[i])
            );
        end
    endgenerate
endmodule

// Optimized fixed bits generator
module FixedBits_optimized #(
    parameter WIDTH = 2
)(
    output wire [WIDTH-1:0] y
);
    // Direct assignment for better synthesis results
    assign y = {WIDTH{1'b1}};
endmodule

// Balanced NAND gate for improved timing
module NAND_balanced(
    input wire a, b,
    output wire y
);
    // Single operation with optimized cell mapping
    assign y = ~(a & b);
endmodule