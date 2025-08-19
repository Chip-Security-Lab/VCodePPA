//SystemVerilog
module double_edge_gen (
    input wire clk_in,
    input wire rst_n,        // Reset signal added
    input wire enable,       // Enable signal added
    output reg clk_out,
    output reg valid_out     // Valid signal added
);
    // Pipeline stage registers
    reg clk_phase_stage1;
    reg clk_phase_stage2;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    
    // Stage 1: Detect clock edge and update phase
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            // Reset stage 1
            clk_phase_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            // First pipeline stage - posedge processing
            clk_phase_stage1 <= ~clk_phase_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Propagate phase information to output on negedge
    always @(negedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            // Reset stage 2
            clk_phase_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            clk_out <= 1'b0;
            valid_out <= 1'b0;
        end else if (enable) begin
            // Second pipeline stage - negedge processing
            clk_phase_stage2 <= clk_phase_stage1;
            valid_stage2 <= valid_stage1;
            
            // Output stage
            clk_out <= clk_phase_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule