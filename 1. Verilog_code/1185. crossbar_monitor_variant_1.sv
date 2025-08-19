//SystemVerilog
module crossbar_monitor #(DW=8, N=4) (
    input clk,
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout,
    output reg [31:0] traffic_count
);
    // 为高扇出信号i添加缓冲寄存器
    reg [31:0] i_buf [0:3];
    reg [31:0] next_traffic_count;
    reg [31:0] next_traffic_count_buf [0:1]; // 缓冲寄存器
    reg [N-1:0] din_active; // 非零输入指示
    
    // 计算每个输入是否有效(非零)
    always @(posedge clk) begin
        for (integer j = 0; j < N; j = j + 1) begin
            din_active[j] <= |din[j];
        end
    end
    
    // 第一级缓冲 - 连接和流量检测
    always @(posedge clk) begin
        // 缓冲i的值用于不同模块
        i_buf[0] <= 0;
        i_buf[1] <= 1;
        i_buf[2] <= 2;
        i_buf[3] <= 3;
        
        // 连接输入到输出
        dout[0] <= din[N-1-i_buf[0]]; // 使用缓冲的索引
        dout[1] <= din[N-1-i_buf[1]];
        dout[2] <= din[N-1-i_buf[2]];
        dout[3] <= din[N-1-i_buf[3]];
        
        // 计算流量增量
        next_traffic_count <= traffic_count + din_active[0] + din_active[1] + 
                                              din_active[2] + din_active[3];
    end
    
    // 流量计数缓冲和更新
    always @(posedge clk) begin
        // 使用缓冲的next_traffic_count更新traffic_count
        traffic_count <= next_traffic_count;
        
        // 为next_traffic_count创建缓冲
        next_traffic_count_buf[0] <= next_traffic_count;
        next_traffic_count_buf[1] <= next_traffic_count;
    end
    
    // 初始化traffic_count为0
    initial begin
        traffic_count = 0;
    end
endmodule