module dram_ctrl_hybrid #(
    parameter MODE = 0 // 0=SDR, 1=DDR
)(
    input clk,
    input ddr_clk,
    output reg [15:0] dq_out
);
    generate
        if(MODE == 1) begin : DDR_MODE
            always @(posedge clk or negedge clk) begin
                dq_out <= #1 ddr_clk ? 16'hF0F0 : 16'h0F0F;
            end
        end else begin : SDR_MODE
            always @(posedge clk) begin
                dq_out <= 16'h1234;
            end
        end
    endgenerate
endmodule
