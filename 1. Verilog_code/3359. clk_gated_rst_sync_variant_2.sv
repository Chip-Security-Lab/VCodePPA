//SystemVerilog
module clk_gated_rst_sync (
    input  wire clk,
    input  wire clk_en,
    input  wire async_rst_n,
    input  wire data_valid_in,    // 输入数据有效信号
    output wire data_valid_out,   // 输出数据有效信号
    output wire sync_rst_n,
    output wire pipeline_ready    // 流水线就绪信号
);
    // 流水线寄存器
    reg [1:0] sync_stages_pipe1;
    reg [1:0] sync_stages_pipe2;
    
    // 流水线控制信号
    reg valid_pipe1;
    reg valid_pipe2;
    
    // 时钟门控
    wire gated_clk;
    reg gated_clk_buf1, gated_clk_buf2;   // 为高扇出的gated_clk增加缓冲寄存器
    
    // 时钟门控实现
    assign gated_clk = clk & clk_en;
    
    // 缓冲gated_clk以减少扇出负载
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            gated_clk_buf1 <= 1'b0;
            gated_clk_buf2 <= 1'b0;
        end
        else begin
            gated_clk_buf1 <= gated_clk;
            gated_clk_buf2 <= gated_clk;
        end
    end
    
    // 流水线控制逻辑
    assign pipeline_ready = 1'b1;  // 该流水线总是准备好接收新数据
    assign data_valid_out = valid_pipe2;
    
    // 第一级流水线 - 使用缓冲的时钟
    always @(posedge gated_clk_buf1 or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_stages_pipe1 <= 2'b00;
            valid_pipe1 <= 1'b0;
        end
        else begin
            sync_stages_pipe1 <= {1'b0, 1'b1};  // 第一级流水线操作
            valid_pipe1 <= data_valid_in;       // 传递有效信号
        end
    end
    
    // 第二级流水线 - 使用另一个缓冲的时钟
    always @(posedge gated_clk_buf2 or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_stages_pipe2 <= 2'b00;
            valid_pipe2 <= 1'b0;
        end
        else begin
            sync_stages_pipe2 <= {sync_stages_pipe1[0], sync_stages_pipe1[1]};  // 第二级流水线操作
            valid_pipe2 <= valid_pipe1;  // 传递有效信号
        end
    end
    
    // 输出逻辑
    assign sync_rst_n = sync_stages_pipe2[1];
    
endmodule