//SystemVerilog
module sync_adaptive_thresh #(
    parameter DW = 8
)(
    input clk, rst,
    input [DW-1:0] signal_in,
    input [DW-1:0] background,
    input [DW-1:0] sensitivity,
    output reg out_bit,
    // Pipeline control signals
    input valid_in,
    output reg valid_out
);
    // Pipeline stage 1: Input registers
    reg [DW-1:0] signal_in_stage1;
    reg [DW-1:0] background_stage1;
    reg [DW-1:0] sensitivity_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Addition operation
    reg [DW-1:0] signal_in_stage2;
    reg [DW-1:0] threshold_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Comparison operation
    reg compare_result_stage3;
    reg valid_stage3;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            signal_in_stage1 <= 0;
            background_stage1 <= 0;
            sensitivity_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            signal_in_stage1 <= signal_in;
            background_stage1 <= background;
            sensitivity_stage1 <= sensitivity;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2: Addition operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            signal_in_stage2 <= 0;
            threshold_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            signal_in_stage2 <= signal_in_stage1;
            threshold_stage2 <= background_stage1 + sensitivity_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Comparison operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            compare_result_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            compare_result_stage3 <= (signal_in_stage2 > threshold_stage2) ? 1'b1 : 1'b0;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_bit <= 0;
            valid_out <= 0;
        end else begin
            out_bit <= compare_result_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule