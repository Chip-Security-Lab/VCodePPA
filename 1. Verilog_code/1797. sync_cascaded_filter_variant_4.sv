//SystemVerilog
module sync_cascaded_filter #(
    parameter DATA_W = 8
)(
    input clk, rst_n,
    input [DATA_W-1:0] in_data,
    output reg [DATA_W-1:0] out_data
);
    reg [DATA_W-1:0] stage1, stage2;
    reg [DATA_W-1:0] stage1_buf1, stage1_buf2;
    wire [DATA_W-1:0] hp_out, lp_out;
    
    // Stage 1: High-pass filter (simple first difference)
    assign hp_out = in_data - stage1_buf1;
    
    // Stage 2: Low-pass filter (simple moving average)
    assign lp_out = (stage1_buf2 + stage2) >> 1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= 0;
            stage1_buf1 <= 0;
            stage1_buf2 <= 0;
            stage2 <= 0;
            out_data <= 0;
        end else begin
            stage1 <= in_data;
            stage1_buf1 <= stage1;  // Buffer for hp_out calculation
            stage1_buf2 <= stage1;  // Buffer for lp_out calculation
            stage2 <= stage1;
            out_data <= lp_out;
        end
    end
endmodule