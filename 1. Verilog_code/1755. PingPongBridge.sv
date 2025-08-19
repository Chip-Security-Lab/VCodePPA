module PingPongBridge #(
    parameter DATA_W = 64
)(
    input src_clk, dst_clk, 
    input [DATA_W-1:0] data_in,
    input valid_in,
    output reg [DATA_W-1:0] data_out,
    output valid_out
);
    reg [DATA_W-1:0] buf0, buf1;
    reg src_sel, dst_sel;
    wire cdc_sync;

    // 初始化寄存器
    initial begin
        buf0 = 0;
        buf1 = 0;
        src_sel = 0;
        dst_sel = 0;
    end

    always @(posedge src_clk) begin
        if (valid_in) begin
            if (!src_sel) buf0 <= data_in;
            else buf1 <= data_in;
            src_sel <= ~src_sel;
        end
    end

    // 实现2-FF同步器
    reg sync_ff1, sync_ff2;
    
    always @(posedge dst_clk) begin
        sync_ff1 <= src_sel;
        sync_ff2 <= sync_ff1;
    end
    
    assign cdc_sync = sync_ff2;

    always @(posedge dst_clk) begin
        dst_sel <= cdc_sync;
        data_out <= dst_sel ? buf1 : buf0;
    end
    assign valid_out = (dst_sel != cdc_sync);
endmodule