//SystemVerilog
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

    // 源时钟域流水线
    reg [DATA_W-1:0] data_in_stage1;
    reg valid_in_stage1;
    reg src_sel_stage1;
    
    // 扇出缓冲寄存器 - 为高扇出信号src_sel添加缓冲
    reg src_sel_buf1, src_sel_buf2;
    
    always @(posedge src_clk) begin
        data_in_stage1 <= data_in;
        valid_in_stage1 <= valid_in;
        
        // 更新src_sel缓冲器
        src_sel_buf1 <= src_sel;
        src_sel_buf2 <= src_sel;
        
        // 使用缓冲后的信号
        src_sel_stage1 <= src_sel_buf1;
    end

    always @(posedge src_clk) begin
        if (valid_in_stage1) begin
            if (!src_sel_stage1) buf0 <= data_in_stage1;
            else buf1 <= data_in_stage1;
            src_sel <= ~src_sel_stage1;
        end
    end

    // 跨时钟域同步器流水线
    reg sync_ff1, sync_ff2, sync_ff3;
    
    always @(posedge dst_clk) begin
        // 使用第二个缓冲器送入CDC同步器，减轻src_sel负载
        sync_ff1 <= src_sel_buf2;
        sync_ff2 <= sync_ff1;
        sync_ff3 <= sync_ff2;
    end
    
    assign cdc_sync = sync_ff3;

    // 目标时钟域流水线
    reg dst_sel_stage1;
    reg [DATA_W-1:0] data_out_stage1;
    
    always @(posedge dst_clk) begin
        dst_sel_stage1 <= cdc_sync;
        dst_sel <= dst_sel_stage1;
        data_out_stage1 <= dst_sel_stage1 ? buf1 : buf0;
        data_out <= data_out_stage1;
    end
    
    assign valid_out = (dst_sel != cdc_sync);
endmodule