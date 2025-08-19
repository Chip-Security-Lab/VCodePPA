//SystemVerilog
module enable_xnor (
    input  wire clk,       // Clock input
    input  wire rst_n,     // Active-low reset
    input  wire enable,    // Enable signal
    input  wire a,         // Input operand A
    input  wire b,         // Input operand B
    output reg  y          // Output result
);

    // Internal signals for pipelined data path
    reg stage1_enable, stage1_a, stage1_b;  // Stage 1 registers
    reg stage2_enable, stage2_xnor_result;  // Stage 2 registers
    
    // Combinational logic for XNOR operation
    wire xnor_result;
    assign xnor_result = ~(stage1_a ^ stage1_b);
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_enable <= 1'b0;
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_enable <= enable;
            stage1_a <= a;
            stage1_b <= b;
        end
    end
    
    // Stage 2: Calculate XNOR and apply enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_enable <= 1'b0;
            stage2_xnor_result <= 1'b0;
        end else begin
            stage2_enable <= stage1_enable;
            stage2_xnor_result <= xnor_result;
        end
    end
    
    // Output stage: Apply enable to result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage2_enable ? stage2_xnor_result : 1'b0;
        end
    end

endmodule