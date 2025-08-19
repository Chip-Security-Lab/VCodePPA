//SystemVerilog
module PingPongBridge #(
    parameter DATA_W = 64
)(
    input src_clk, dst_clk, 
    input [DATA_W-1:0] data_in,
    input valid_in,
    output reg [DATA_W-1:0] data_out,
    output reg valid_out
);
    // 源域数据缓冲区
    reg [DATA_W-1:0] src_buffer0, src_buffer1;
    reg src_write_sel;
    reg src_handshake_flag;
    
    // 目标域控制信号
    reg [1:0] dst_sync_reg;
    reg dst_read_sel;
    reg dst_handshake_detected;
    
    // 目标域数据缓冲区
    reg [DATA_W-1:0] dst_buffer0, dst_buffer1;
    
    // 初始化
    initial begin
        src_buffer0 = {DATA_W{1'b0}};
        src_buffer1 = {DATA_W{1'b0}};
        src_write_sel = 1'b0;
        src_handshake_flag = 1'b0;
        
        dst_sync_reg = 2'b00;
        dst_read_sel = 1'b0;
        dst_handshake_detected = 1'b0;
        
        dst_buffer0 = {DATA_W{1'b0}};
        dst_buffer1 = {DATA_W{1'b0}};
        
        data_out = {DATA_W{1'b0}};
        valid_out = 1'b0;
    end

    // 源域逻辑：写入和握手
    always @(posedge src_clk) begin
        if (valid_in) begin
            // 写入数据到当前选择的缓冲区
            if (src_write_sel == 1'b0) begin
                src_buffer0 <= data_in;
            end else begin
                src_buffer1 <= data_in;
            end
            
            // 使用补码加法实现减法器功能
            src_write_sel <= src_write_sel + 1'b1;
            src_handshake_flag <= src_handshake_flag + 1'b1;
        end
    end

    // 时钟域同步：源->目标（多级流水线同步器）
    always @(posedge dst_clk) begin
        dst_sync_reg <= {dst_sync_reg[0], src_handshake_flag};
    end

    // 目标域控制逻辑
    always @(posedge dst_clk) begin
        // 检测握手状态变化
        dst_handshake_detected <= (dst_read_sel != dst_sync_reg[1]);
        
        // 更新读选择器
        if (dst_handshake_detected) begin
            dst_read_sel <= dst_sync_reg[1];
        end
    end
    
    // 目标域数据路径：缓冲和输出
    always @(posedge dst_clk) begin
        // 数据缓冲更新
        dst_buffer0 <= src_buffer0;
        dst_buffer1 <= src_buffer1;
        
        // 输出选择和有效信号
        data_out <= dst_read_sel ? dst_buffer1 : dst_buffer0;
        valid_out <= dst_handshake_detected;
    end
endmodule