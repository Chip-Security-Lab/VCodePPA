//SystemVerilog
module multi_phase_div #(parameter N=4) (
    input wire clk,
    input wire rst,
    input wire enable,
    output reg [3:0] phase_out
);
    // Optimized phase encoding - use one-hot encoding directly in registers
    // This reduces path delay by simplifying the phase state transition logic
    reg [3:0] phase_data_stage2;
    reg [3:0] phase_data_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pre-decode phase transitions with simplified counter logic
    // Use a single counter instead of propagating through stages
    reg [1:0] counter;
    
    // Stage 1: Counter logic with simplified reset path
    always @(posedge clk) begin
        if (rst) begin
            counter <= 2'd0;
            valid_stage1 <= 1'b0;
        end 
        else if (enable) begin
            // Balance path delay by computing next state directly
            counter <= counter + 1'b1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Optimized phase computation using direct mapping
    // Pre-compute phase data to reduce critical path length
    reg [3:0] next_phase;
    
    always @(*) begin
        case(counter)
            2'd0: next_phase = 4'b0010;
            2'd1: next_phase = 4'b0100;
            2'd2: next_phase = 4'b1000;
            2'd3: next_phase = 4'b0001;
            default: next_phase = 4'b0001;
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            phase_data_stage2 <= 4'b0001;
            valid_stage2 <= 1'b0;
        end 
        else if (enable) begin
            // Use pre-computed next_phase to reduce logic depth
            phase_data_stage2 <= next_phase;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Balanced pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            phase_data_stage3 <= 4'b0001;
            valid_stage3 <= 1'b0;
        end 
        else if (enable) begin
            phase_data_stage3 <= phase_data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final output with simplified condition
    always @(posedge clk) begin
        if (rst) begin
            phase_out <= 4'b0001;
        end 
        else if (enable & valid_stage3) begin  // Use & instead of && for better synthesis
            phase_out <= phase_data_stage3;
        end
    end
endmodule