//SystemVerilog (IEEE 1364-2005)
// Top level module - AND gate with enable signal (deeply pipelined)
module and_gate_enable (
    input  wire clk,     // System clock
    input  wire rst_n,   // Active low reset
    input  wire a,       // Input A
    input  wire b,       // Input B
    input  wire enable,  // Enable signal
    output wire y        // Output Y
);
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Input stage registers
    reg a_stage1, b_stage1, enable_stage1;
    
    // Intermediate pipeline registers
    reg a_stage2, b_stage2, enable_stage2;
    reg and_result_stage3;
    reg enable_stage3;
    reg gated_result_stage4;
    
    // Stage 1: Register inputs and generate valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            enable_stage1 <= enable;
            valid_stage1 <= 1'b1; // Data is valid after first clock
        end
    end
    
    // Stage 2: Forward registered inputs to next stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 1'b0;
            b_stage2 <= 1'b0;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Perform AND operation and register result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_stage3 <= 1'b0;
            enable_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            and_result_stage3 <= a_stage2 & b_stage2; // AND operation
            enable_stage3 <= enable_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Apply enable control and register final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gated_result_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            gated_result_stage4 <= enable_stage3 ? and_result_stage3 : 1'b0;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Output assignment
    assign y = gated_result_stage4;
    
    // Basic AND and enable control operations are now integrated into the pipeline
    // The following modules are not needed in the new design as their functionality
    // is incorporated into the pipeline stages above
    
endmodule