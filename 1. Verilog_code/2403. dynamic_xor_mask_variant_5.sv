//SystemVerilog
//IEEE 1364-2005 Verilog
module dynamic_xor_mask #(
    parameter WIDTH = 64
)(
    input clk, en, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Stage 1: Mask generation
    reg [WIDTH-1:0] mask_reg;
    reg [WIDTH-1:0] mask_stage1;
    reg [WIDTH-1:0] data_in_stage1;
    reg en_stage1;
    
    // Stage 2: Mask preprocessing 
    reg [WIDTH-1:0] mask_stage2;
    reg [WIDTH-1:0] data_in_stage2;
    reg en_stage2;
    
    // Stage 3: XOR operation - split into four parts
    reg [WIDTH/4-1:0] xor_result_stage3_part1;
    reg [WIDTH/4-1:0] xor_result_stage3_part2;
    reg [WIDTH/4-1:0] xor_result_stage3_part3;
    reg [WIDTH/4-1:0] xor_result_stage3_part4;
    reg en_stage3;
    
    // Stage 4: Intermediate combination
    reg [WIDTH/2-1:0] xor_result_stage4_lower;
    reg [WIDTH/2-1:0] xor_result_stage4_upper;
    reg en_stage4;
    
    // Stage 5: Final output assembly
    
    // Stage 1: Mask generation and data registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mask_reg <= {WIDTH{1'b0}};
            mask_stage1 <= {WIDTH{1'b0}};
            data_in_stage1 <= {WIDTH{1'b0}};
            en_stage1 <= 1'b0;
        end else begin
            en_stage1 <= en;
            if (en) begin
                mask_reg <= mask_reg ^ 32'h9E3779B9;
                mask_stage1 <= mask_reg ^ 32'h9E3779B9;
                data_in_stage1 <= data_in;
            end
        end
    end
    
    // Stage 2: Mask preprocessing stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mask_stage2 <= {WIDTH{1'b0}};
            data_in_stage2 <= {WIDTH{1'b0}};
            en_stage2 <= 1'b0;
        end else begin
            en_stage2 <= en_stage1;
            if (en_stage1) begin
                mask_stage2 <= mask_stage1;
                data_in_stage2 <= data_in_stage1;
            end
        end
    end
    
    // Stage 3: Split XOR operation into four parallel parts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_stage3_part1 <= {(WIDTH/4){1'b0}};
            xor_result_stage3_part2 <= {(WIDTH/4){1'b0}};
            xor_result_stage3_part3 <= {(WIDTH/4){1'b0}};
            xor_result_stage3_part4 <= {(WIDTH/4){1'b0}};
            en_stage3 <= 1'b0;
        end else begin
            en_stage3 <= en_stage2;
            if (en_stage2) begin
                // Process quarter 1 (lowest)
                xor_result_stage3_part1 <= data_in_stage2[WIDTH/4-1:0] ^ mask_stage2[WIDTH/4-1:0];
                // Process quarter 2
                xor_result_stage3_part2 <= data_in_stage2[WIDTH/2-1:WIDTH/4] ^ mask_stage2[WIDTH/2-1:WIDTH/4];
                // Process quarter 3
                xor_result_stage3_part3 <= data_in_stage2[3*WIDTH/4-1:WIDTH/2] ^ mask_stage2[3*WIDTH/4-1:WIDTH/2];
                // Process quarter 4 (highest)
                xor_result_stage3_part4 <= data_in_stage2[WIDTH-1:3*WIDTH/4] ^ mask_stage2[WIDTH-1:3*WIDTH/4];
            end
        end
    end
    
    // Stage 4: Intermediate combination of results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_stage4_lower <= {(WIDTH/2){1'b0}};
            xor_result_stage4_upper <= {(WIDTH/2){1'b0}};
            en_stage4 <= 1'b0;
        end else begin
            en_stage4 <= en_stage3;
            if (en_stage3) begin
                // Combine lower quarters
                xor_result_stage4_lower <= {xor_result_stage3_part2, xor_result_stage3_part1};
                // Combine upper quarters
                xor_result_stage4_upper <= {xor_result_stage3_part4, xor_result_stage3_part3};
            end
        end
    end
    
    // Stage 5: Final output assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end else if (en_stage4) begin
            // Combine the results from stage 4
            data_out <= {xor_result_stage4_upper, xor_result_stage4_lower};
        end
    end
endmodule