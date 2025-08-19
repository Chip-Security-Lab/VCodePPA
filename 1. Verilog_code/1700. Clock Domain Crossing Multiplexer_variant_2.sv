//SystemVerilog
module cdc_mux(
    input clk_src, clk_dst, rst_n,
    input [15:0] data_a, data_b,
    input select,
    output reg [15:0] synced_out
);
    reg [15:0] mux_out;
    reg [15:0] meta_stage1;
    reg [15:0] meta_stage2;
    
    always @(*) 
        mux_out = select ? data_b : data_a;
    
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            meta_stage1 <= 16'd0;
            meta_stage2 <= 16'd0;
            synced_out <= 16'd0;
        end else begin
            meta_stage1 <= mux_out;
            meta_stage2 <= meta_stage1;
            synced_out <= meta_stage2;
        end
    end
endmodule