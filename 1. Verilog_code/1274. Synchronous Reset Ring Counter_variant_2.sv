//SystemVerilog
module sync_reset_ring_counter(
    input wire clock,
    input wire reset,      // Active-high reset
    input wire enable,     // Pipeline enable signal
    output reg [3:0] out,
    output reg valid_out   // Indicates output is valid
);
    // Retimed pipeline structure
    reg [3:0] next_data;
    reg [3:0] stage1_data;
    reg [3:0] stage2_data;
    reg valid_next, valid_stage1, valid_stage2;
    
    // Pre-computation stage - retimed from the output stage
    always @(*) begin
        next_data = out[3] ? {out[2:0], 1'b1} : {out[2:0], 1'b0};
        valid_next = 1'b1;
    end
    
    // Pipeline Stage 1: First register stage
    always @(posedge clock) begin
        if (reset) begin
            stage1_data <= 4'b0001;  // Initial state
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            stage1_data <= next_data;
            valid_stage1 <= valid_next;
        end
    end
    
    // Pipeline Stage 2: Second register stage
    always @(posedge clock) begin
        if (reset) begin
            stage2_data <= 4'b0001;
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            stage2_data <= stage1_data;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final output register
    always @(posedge clock) begin
        if (reset) begin
            out <= 4'b0001;
            valid_out <= 1'b0;
        end
        else if (enable) begin
            out <= stage2_data;
            valid_out <= valid_stage2;
        end
    end
endmodule