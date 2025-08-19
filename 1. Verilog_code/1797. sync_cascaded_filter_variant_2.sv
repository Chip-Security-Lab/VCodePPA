//SystemVerilog
module sync_cascaded_filter #(
    parameter DATA_W = 8
)(
    input clk, rst_n,
    input [DATA_W-1:0] in_data,
    output reg [DATA_W-1:0] out_data
);
    reg [DATA_W-1:0] in_data_reg, stage2;
    wire [DATA_W-1:0] hp_out, lp_out;
    
    // Combined always block for all sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_reg <= 0;
            stage2 <= 0;
            out_data <= 0;
        end else begin
            in_data_reg <= in_data;
            stage2 <= in_data_reg;
            out_data <= lp_out;
        end
    end
    
    // Stage 1: High-pass filter (simple first difference)
    assign hp_out = in_data - in_data_reg;
    
    // Stage 2: Low-pass filter (simple moving average)
    assign lp_out = (in_data_reg + stage2) >> 1;
    
endmodule