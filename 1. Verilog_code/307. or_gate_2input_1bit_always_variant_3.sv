//SystemVerilog
module or_gate_2input_1bit_always (
    input wire clk,
    input wire rst_n,
    input wire a,
    input wire b,
    output reg y
);
    // Input pipeline registers - increased pipeline depth
    reg a_stage1, b_stage1;       // First pipeline stage
    reg a_stage2, b_stage2;       // Second pipeline stage
    reg a_stage3, b_stage3;       // Third pipeline stage
    
    // Intermediate computation registers
    reg partial_or_stage4;        // Fourth pipeline stage
    reg or_result_stage5;         // Fifth pipeline stage
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    // Second pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 1'b0;
            b_stage2 <= 1'b0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
        end
    end
    
    // Third pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage3 <= 1'b0;
            b_stage3 <= 1'b0;
        end else begin
            a_stage3 <= a_stage2;
            b_stage3 <= b_stage2;
        end
    end
    
    // Fourth pipeline stage - perform OR operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_or_stage4 <= 1'b0;
        end else begin
            partial_or_stage4 <= a_stage3 | b_stage3;
        end
    end
    
    // Fifth pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_stage5 <= 1'b0;
        end else begin
            or_result_stage5 <= partial_or_stage4;
        end
    end
    
    // Final output assignment - sixth pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= or_result_stage5;
        end
    end
endmodule