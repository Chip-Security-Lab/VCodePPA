//SystemVerilog
module int_ctrl_delay #(
    parameter DLY = 2  // 延迟级数参数
)(
    input  wire       clk,     // 系统时钟
    input  wire       int_in,  // 中断输入信号
    output wire       int_out  // 延迟后的中断输出信号
);

    // 定义延迟链寄存器和缓冲寄存器
    reg [DLY-1:0] delay_pipeline;
    reg [DLY-1:0] delay_pipeline_buf1;
    reg [DLY-1:0] delay_pipeline_buf2;
    
    // 定义循环变量的缓冲寄存器
    reg [31:0] loop_index_buf1, loop_index_buf2;
    
    // 实现流水线结构的延迟链
    always @(posedge clk) begin
        // 移位操作 - 将输入信号送入管道的第一级
        delay_pipeline[0] <= int_in;
        
        // 缓冲delay_pipeline以减少扇出负载
        delay_pipeline_buf1 <= delay_pipeline;
        delay_pipeline_buf2 <= delay_pipeline_buf1;
        
        // 数据在流水线中的流动 - 实现逐级传递
        if (DLY > 1) begin
            // 使用缓冲的循环索引减少高扇出
            loop_index_buf1 <= 1;
            loop_index_buf2 <= loop_index_buf1;
            
            for (integer i = 1; i < DLY; i = i + 1) begin
                // 使用均衡负载的方式更新delay_pipeline
                if (i < DLY/2) begin
                    delay_pipeline[i] <= delay_pipeline_buf1[i-1];
                end else begin
                    delay_pipeline[i] <= delay_pipeline_buf2[i-1];
                end
            end
        end
    end

    // 添加输出缓冲寄存器以减少关键路径
    reg int_out_reg;
    
    always @(posedge clk) begin
        int_out_reg <= delay_pipeline[DLY-1];
    end

    // 输出映射
    assign int_out = int_out_reg;

endmodule