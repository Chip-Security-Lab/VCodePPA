//SystemVerilog
module updown_load_counter (
    input  wire       clk,       // 时钟信号
    input  wire       rst_n,     // 低电平有效的复位信号
    input  wire       load,      // 加载信号
    input  wire       up_down,   // 计数方向控制：1=递增，0=递减
    input  wire [7:0] data_in,   // 8位输入数据
    output reg  [7:0] q          // 8位计数器输出
);
    // 内部流水线信号定义
    reg        up_down_r;        // 寄存方向控制信号
    reg [7:0]  q_stage1;         // 第一级流水线寄存器
    reg        load_r;           // 寄存加载信号
    reg [7:0]  data_in_r;        // 寄存输入数据
    
    // 计算逻辑阶段
    wire [7:0] incr_result;      // 递增结果
    wire [7:0] decr_result;      // 递减结果
    wire [7:0] count_result;     // 计数结果
    
    // 第一级流水线 - 寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            up_down_r <= 1'b0;
            load_r    <= 1'b0;
            data_in_r <= 8'h00;
            q_stage1  <= 8'h00;
        end
        else begin
            up_down_r <= up_down;
            load_r    <= load;
            data_in_r <= data_in;
            q_stage1  <= q;
        end
    end
    
    // 分离递增和递减计算路径，减少逻辑深度
    assign incr_result = q_stage1 + 1'b1;
    assign decr_result = q_stage1 - 1'b1;
    
    // 使用多路复用器选择适当的计数结果
    assign count_result = up_down_r ? incr_result : decr_result;
    
    // 第二级流水线 - 更新计数器输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 8'h00;
        end
        else if (load_r) begin
            q <= data_in_r;
        end
        else begin
            q <= count_result;
        end
    end
    
endmodule