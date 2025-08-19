//SystemVerilog
module nand2_14 (
    input wire A, B,
    input wire clk,
    input wire reset_n,   // Active-low reset
    input wire valid_in,  // Input valid signal
    output wire valid_out, // Output valid signal
    output wire Y         // Output from final stage
);
    // Pipeline stage 1 - Input registration
    reg stage1_A, stage1_B;
    reg stage1_valid;
    
    // Pipeline stage 2 - Initial computation: A & B
    reg stage2_and_result;
    reg stage2_valid;
    
    // Pipeline stage 3 - Further computation: Inversion
    reg stage3_nand_result;
    reg stage3_valid;
    
    // Pipeline stage 4 - Output buffering
    reg stage4_result;
    reg stage4_valid;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
            stage1_valid <= valid_in;
        end
    end
    
    // Stage 2: Perform AND operation and register intermediate result
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage2_and_result <= 1'b0;
            stage2_valid <= 1'b0;
        end else begin
            stage2_and_result <= stage1_A & stage1_B;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Stage 3: Perform NOT operation on the AND result
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage3_nand_result <= 1'b1;  // Default NAND output is 1
            stage3_valid <= 1'b0;
        end else begin
            stage3_nand_result <= ~stage2_and_result;
            stage3_valid <= stage2_valid;
        end
    end
    
    // Stage 4: Output buffering for better timing
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage4_result <= 1'b1;
            stage4_valid <= 1'b0;
        end else begin
            stage4_result <= stage3_nand_result;
            stage4_valid <= stage3_valid;
        end
    end
    
    // Connect output signals
    assign Y = stage4_result;
    assign valid_out = stage4_valid;
    
endmodule