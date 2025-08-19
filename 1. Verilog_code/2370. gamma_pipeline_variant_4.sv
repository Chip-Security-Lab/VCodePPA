//SystemVerilog
module gamma_pipeline (
    input clk,
    input rst_n,
    input valid_in,
    input [7:0] in,
    output reg valid_out,
    output reg [7:0] out,
    output reg ready_in
);
    // Pipeline stage valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline data registers
    reg [7:0] in_stage1;
    reg [7:0] mul_result_stage1;
    reg [7:0] stage2;
    
    // Wire connections
    wire [7:0] mul_result;
    
    // Ready signal - always ready in this implementation
    always @(*) begin
        ready_in = 1'b1;
    end

    // Stage 0: Register input and generate valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid_in && ready_in) begin
                in_stage1 <= in;
                valid_stage1 <= valid_in;
            end else if (valid_stage1 && !valid_in) begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // Instantiate Dadda multiplier
    dadda_mul8x2 dadda_inst (
        .a(in_stage1),
        .b(8'h02),  // Multiply by 2
        .product(mul_result)
    );

    // Stage 1: Linear scaling using Dadda multiplier
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_result_stage1 <= 8'h0;
            valid_stage2 <= 1'b0;
        end else begin
            mul_result_stage1 <= mul_result;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 2: Offset adjust
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2 <= 8'h0;
            valid_stage3 <= 1'b0;
        end else begin
            stage2 <= mul_result_stage1 - 15;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 3: Final scaling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h0;
            valid_out <= 1'b0;
        end else begin
            out <= stage2 >> 1;
            valid_out <= valid_stage3;
        end
    end
endmodule

// Enhanced Dadda multiplier 8x2 implementation with balanced pipeline stages
module dadda_mul8x2 (
    input [7:0] a,
    input [7:0] b,
    output [7:0] product
);
    // Partial products generation
    wire [15:0] partial_product_0;
    wire [15:0] partial_product_1;
    wire [15:0] final_sum;
    
    // Generate individual partial products
    assign partial_product_0 = (b[0]) ? {8'b0, a} : 16'b0;
    assign partial_product_1 = (b[1]) ? {7'b0, a, 1'b0} : 16'b0;
    
    // Dadda reduction for 8x2 case
    assign final_sum = partial_product_0 + partial_product_1;
    
    // Final product (truncated to 8 bits)
    assign product = final_sum[7:0];
endmodule