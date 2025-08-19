//SystemVerilog
module counter_mac #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                rst,
    input  wire [WIDTH-1:0]    a, b,
    input  wire                valid_in,
    output wire                valid_out,
    output wire [2*WIDTH-1:0]  sum
);

    // 流水线寄存器 - 第1级：输入缓存
    reg [WIDTH-1:0]     a_stage1, b_stage1;
    reg                 valid_stage1;
    
    // 流水线寄存器 - 第2级：乘法运算
    reg [2*WIDTH-1:0]   mult_result_stage2;
    reg                 valid_stage2;
    
    // 流水线寄存器 - 第3级：累加运算准备
    reg [2*WIDTH-1:0]   mult_result_stage3;
    reg                 valid_stage3;
    
    // 流水线寄存器 - 第4级：累加结果
    reg [2*WIDTH-1:0]   sum_reg_stage4;
    reg                 valid_stage4;
    
    // 流水线控制信号
    reg                 pipeline_flush;
    
    // Stage 1: 输入缓存
    always @(posedge clk) begin
        if (rst) begin
            a_stage1 <= 0;
            b_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: 乘法运算
    always @(posedge clk) begin
        if (rst) begin
            mult_result_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            mult_result_stage2 <= a_stage1 * b_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: 累加准备
    always @(posedge clk) begin
        if (rst) begin
            mult_result_stage3 <= 0;
            valid_stage3 <= 0;
        end
        else begin
            mult_result_stage3 <= mult_result_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: 累加运算
    always @(posedge clk) begin
        if (rst) begin
            sum_reg_stage4 <= 0;
            valid_stage4 <= 0;
            pipeline_flush <= 0;
        end
        else begin
            if (valid_stage3) begin
                sum_reg_stage4 <= sum_reg_stage4 + mult_result_stage3;
            end
            valid_stage4 <= valid_stage3;
            
            // 流水线冲刷控制 (可由外部信号触发，此处简化)
            pipeline_flush <= 1'b0;
        end
    end
    
    // 添加前递逻辑 - 处理数据依赖
    wire [2*WIDTH-1:0] forwarded_sum;
    wire sum_forwarding_needed;
    
    // 检测是否需要前递 (当有新计算结果即将写入但尚未写入寄存器时)
    assign sum_forwarding_needed = valid_stage3 && valid_stage4;
    
    // 根据前递条件选择输出
    assign forwarded_sum = sum_forwarding_needed ? 
                           (sum_reg_stage4 + mult_result_stage3) : 
                           sum_reg_stage4;
    
    // 输出赋值
    assign sum = forwarded_sum;
    assign valid_out = valid_stage4;

endmodule