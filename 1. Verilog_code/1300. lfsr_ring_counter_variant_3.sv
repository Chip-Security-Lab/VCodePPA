//SystemVerilog
module lfsr_ring_counter (
    input wire clk,
    input wire rst_n,  // Added reset signal for pipeline control
    input wire enable,
    input wire valid_in,  // Input valid signal
    output wire valid_out,  // Output valid signal
    output wire [3:0] lfsr_out  // Changed to wire as output comes from pipeline
);
    // Pipeline stage registers
    reg [3:0] lfsr_stage1, lfsr_stage2, lfsr_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Initial LFSR computation
    wire [3:0] next_lfsr_stage1 = enable ? {lfsr_stage3[0], lfsr_stage3[3:1]} : 4'b0001;
    
    // First pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
        end else begin
            lfsr_stage1 <= next_lfsr_stage1;
            valid_stage1 <= valid_in;
        end
    end
    
    // Second pipeline stage - bit manipulation operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            lfsr_stage2 <= lfsr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Third pipeline stage - final output preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end else begin
            lfsr_stage3 <= lfsr_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignments
    assign lfsr_out = lfsr_stage3;
    assign valid_out = valid_stage3;
    
endmodule