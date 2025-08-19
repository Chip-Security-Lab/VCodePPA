//SystemVerilog
module Timer_PhaseAdjust (
    input wire clk,
    input wire rst_n,
    input wire [3:0] phase,
    output reg out_pulse
);
    // Pipeline stage 1 signals
    reg [3:0] cnt_stage1;
    reg [3:0] phase_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 signals
    reg compare_result_stage2;
    reg valid_stage2;
    
    // Stage 1: Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 4'h0;
        end else begin
            cnt_stage1 <= cnt_stage1 + 4'h1;
        end
    end
    
    // Stage 1: Phase registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_stage1 <= 4'h0;
        end else begin
            phase_stage1 <= phase;
        end
    end
    
    // Stage 1: Valid signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Comparison logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compare_result_stage2 <= 1'b0;
        end else begin
            compare_result_stage2 <= (cnt_stage1 == phase_stage1);
        end
    end
    
    // Stage 2: Valid signal propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage: Final pulse generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_pulse <= 1'b0;
        end else begin
            out_pulse <= valid_stage2 ? compare_result_stage2 : 1'b0;
        end
    end
endmodule