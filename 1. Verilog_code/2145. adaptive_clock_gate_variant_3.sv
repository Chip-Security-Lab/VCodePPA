//SystemVerilog
module adaptive_clock_gate (
    input  wire clk_in,
    input  wire [7:0] activity_level,
    input  wire rst_n,
    output wire clk_out
);
    // Stage 1: Compare activity level
    reg compare_result_stage1;
    reg valid_stage1;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            compare_result_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            compare_result_stage1 <= (activity_level > 8'd10);
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Generate gate control signal
    reg gate_enable_stage2;
    reg valid_stage2;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            gate_enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            gate_enable_stage2 <= compare_result_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final output stage
    assign clk_out = clk_in & (gate_enable_stage2 & valid_stage2);
endmodule