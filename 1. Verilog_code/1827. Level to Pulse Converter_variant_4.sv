//SystemVerilog
module level2pulse_converter (
    input  wire clk_i,
    input  wire rst_i,  // Active high reset
    input  wire level_i,
    output reg  pulse_o
);
    // Stage 1 registers
    reg level_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg level_stage2;
    reg level_r_stage2;
    reg valid_stage2;
    
    // Stage 1: Input registration and validation
    always @(posedge clk_i) begin
        if (rst_i) begin
            level_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            level_stage1 <= level_i;
            valid_stage1 <= 1'b1;  // Data valid signal
        end
    end
    
    // Stage 2: Edge detection calculation
    always @(posedge clk_i) begin
        if (rst_i) begin
            level_stage2 <= 1'b0;
            level_r_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            level_stage2 <= level_stage1;
            level_r_stage2 <= level_r_stage2;  // Maintain previous value
            if (valid_stage1) begin
                level_r_stage2 <= level_stage1;  // Update with new value
                valid_stage2 <= valid_stage1;
            end
        end
    end
    
    // Output stage: Generate pulse
    always @(posedge clk_i) begin
        if (rst_i) begin
            pulse_o <= 1'b0;
        end else if (valid_stage2) begin
            pulse_o <= level_stage2 & ~level_r_stage2;  // Rising edge detection
        end else begin
            pulse_o <= 1'b0;
        end
    end
endmodule