//SystemVerilog
module power_on_reset_sync (
    input  wire clk,
    input  wire ext_rst_n,
    output wire por_rst_n
);
    // 内部寄存器声明
    reg [2:0] por_counter_ff;
    reg [1:0] ext_rst_sync_ff;
    reg       por_done_ff;
    
    // 组合逻辑信号
    reg [2:0] por_counter_next;
    reg       por_done_next;
    
    // 初始化
    initial begin
        por_counter_ff = 3'b000;
        por_done_ff = 1'b0;
        ext_rst_sync_ff = 2'b00;
    end
    
    // 组合逻辑部分 - 生成下一状态
    always @(*) begin
        // 默认保持当前值
        por_counter_next = por_counter_ff;
        por_done_next = por_done_ff;
        
        // 计数器逻辑
        if (!por_done_ff && por_counter_ff < 3'b111) begin
            por_counter_next = por_counter_ff + 1'b1;
        end
        
        // 完成标志逻辑
        if (!por_done_ff && por_counter_ff == 3'b111) begin
            por_done_next = 1'b1;
        end
    end
    
    // 时序逻辑部分 - 状态寄存器更新
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_counter_ff <= 3'b000;
            ext_rst_sync_ff <= 2'b00;
            por_done_ff <= 1'b0;
        end else begin
            ext_rst_sync_ff <= {ext_rst_sync_ff[0], 1'b1};
            por_counter_ff <= por_counter_next;
            por_done_ff <= por_done_next;
        end
    end
    
    // 输出组合逻辑
    assign por_rst_n = ext_rst_sync_ff[1] & por_done_ff;
endmodule