//SystemVerilog
module threshold_reset_gen(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [7:0] signal_value,
    input wire [7:0] threshold,
    output reg reset_out,
    output reg valid_out
);
    // Stage 1 registers and signals
    reg [7:0] signal_value_stage1;
    reg [7:0] threshold_stage1;
    reg valid_stage1;
    
    // Stage 2 signals
    wire comparison_result_stage2;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        if (!rst_n) begin
            signal_value_stage1 <= 8'b0;
            threshold_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end
        else if (valid_in) begin
            signal_value_stage1 <= signal_value;
            threshold_stage1 <= threshold;
            valid_stage1 <= 1'b1;
        end
        else begin
            signal_value_stage1 <= signal_value_stage1;
            threshold_stage1 <= threshold_stage1;
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Comparison logic - optimized for faster evaluation
    assign comparison_result_stage2 = valid_stage1 && (signal_value_stage1 > threshold_stage1);
    
    // Stage 3: Output registration - flattened structure
    always @(posedge clk) begin
        if (!rst_n) begin
            reset_out <= 1'b0;
            valid_out <= 1'b0;
        end
        else if (valid_stage1) begin
            reset_out <= comparison_result_stage2;
            valid_out <= 1'b1;
        end
        else begin
            reset_out <= 1'b0;
            valid_out <= 1'b0;
        end
    end
endmodule