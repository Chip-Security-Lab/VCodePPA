module gated_clock_sync (
    input src_clk, dst_gclk, rst,
    input data_in,
    output reg data_out
);
    reg sync_stage;
    always @(posedge src_clk) begin
        if(rst) sync_stage <= 0;
        else sync_stage <= data_in;
    end
    always @(posedge dst_gclk) begin
        data_out <= sync_stage;
    end
endmodule