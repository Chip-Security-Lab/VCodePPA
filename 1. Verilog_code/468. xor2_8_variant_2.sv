//SystemVerilog
//IEEE 1364-2005 Verilog
module xor2_8_axi #(parameter WIDTH = 8) (
    input  wire                clk,               // 时钟输入
    input  wire                rst_n,             // 复位信号
    
    // AXI-Stream 输入接口
    input  wire [WIDTH-1:0]    s_axis_tdata,      // 输入数据A+B (交织排列)
    input  wire                s_axis_tvalid,     // 输入数据有效
    input  wire                s_axis_tlast,      // 输入数据包结束标志
    output wire                s_axis_tready,     // 输入接口就绪信号
    
    // AXI-Stream 输出接口
    output wire [WIDTH-1:0]    m_axis_tdata,      // 输出XOR结果
    output wire                m_axis_tvalid,     // 输出数据有效
    output wire                m_axis_tlast,      // 输出数据包结束标志
    input  wire                m_axis_tready      // 下游模块就绪信号
);
    // 全局时钟树缓冲器
    wire clk_buf;
    CLKBUF global_clk_buffer (.clk_in(clk), .clk_out(clk_buf));
    
    // 内部信号定义
    reg  [WIDTH-1:0] a_data, b_data;              // 解析交织的输入数据
    reg  [WIDTH-1:0] pipeline_data [2:0];         // 流水线数据寄存器
    reg  [2:0]       pipeline_valid;              // 流水线有效位
    reg  [2:0]       pipeline_last;               // 包结束标志
    wire             stage_ready [3:0];           // 各级流水线就绪信号
    
    // 反向传播的流水线就绪信号
    assign stage_ready[3] = m_axis_tready;
    assign stage_ready[2] = !pipeline_valid[2] || stage_ready[3];
    assign stage_ready[1] = !pipeline_valid[1] || stage_ready[2];
    assign stage_ready[0] = !pipeline_valid[0] || stage_ready[1];
    
    // 输入接口就绪信号
    assign s_axis_tready = stage_ready[0];
    
    // 输出接口信号
    assign m_axis_tdata  = pipeline_data[2];
    assign m_axis_tvalid = pipeline_valid[2];
    assign m_axis_tlast  = pipeline_last[2];
    
    // 输入数据解析 - 每个时钟周期处理一对输入
    // 假设s_axis_tdata的低半部分是A，高半部分是B
    always @(*) begin
        a_data = s_axis_tdata[WIDTH/2-1:0];
        b_data = s_axis_tdata[WIDTH-1:WIDTH/2];
    end

    // 第一级流水线 - 数据采集
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_data[0]  <= {WIDTH{1'b0}};
            pipeline_valid[0] <= 1'b0;
            pipeline_last[0]  <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            pipeline_data[0]  <= a_data ^ b_data;  // 直接执行XOR操作
            pipeline_valid[0] <= 1'b1;
            pipeline_last[0]  <= s_axis_tlast;
        end else if (stage_ready[1]) begin
            pipeline_valid[0] <= 1'b0;  // 当数据被下一级接收后清除有效位
        end
    end
    
    // 第二级流水线 - 计算优化
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_data[1]  <= {WIDTH{1'b0}};
            pipeline_valid[1] <= 1'b0;
            pipeline_last[1]  <= 1'b0;
        end else if (pipeline_valid[0] && stage_ready[1] && stage_ready[2]) begin
            pipeline_data[1]  <= pipeline_data[0];  // 传递数据
            pipeline_valid[1] <= pipeline_valid[0];
            pipeline_last[1]  <= pipeline_last[0];
        end else if (stage_ready[2]) begin
            pipeline_valid[1] <= 1'b0;  // 当数据被下一级接收后清除有效位
        end
    end
    
    // 第三级流水线 - 输出级
    always @(posedge clk_buf or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_data[2]  <= {WIDTH{1'b0}};
            pipeline_valid[2] <= 1'b0;
            pipeline_last[2]  <= 1'b0;
        end else if (pipeline_valid[1] && stage_ready[2] && stage_ready[3]) begin
            pipeline_data[2]  <= pipeline_data[1];  // 传递数据
            pipeline_valid[2] <= pipeline_valid[1];
            pipeline_last[2]  <= pipeline_last[1];
        end else if (stage_ready[3]) begin
            pipeline_valid[2] <= 1'b0;  // 当数据被下游接收后清除有效位
        end
    end
    
endmodule

// 时钟缓冲器模块
module CLKBUF (
    input  wire clk_in,
    output wire clk_out
);
    // 时钟缓冲器实现
    assign clk_out = clk_in;
endmodule