//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// 文件: prog_clk_gen.v
// 功能: 可编程时钟分频器，支持动态分频比配置，使用并行前缀加法器实现
///////////////////////////////////////////////////////////////////////////////
module prog_clk_gen(
    input          pclk,       // 原始输入时钟
    input          presetn,    // 异步复位，低电平有效
    input  [7:0]   div_ratio,  // 分频比配置
    output         clk_out     // 生成的输出时钟
);

    // 内部流水线寄存器声明
    reg [7:0]  div_ratio_r;    // 寄存div_ratio以分割数据路径
    reg [7:0]  half_div_r;     // 存储半分频值
    reg [7:0]  counter_r;      // 计数器寄存器
    reg        clk_out_r;      // 输出时钟寄存器
    
    // 并行前缀加法器内部信号
    wire [7:0] next_counter;
    wire [7:0] incr_value = 8'b00000001; // 增量值
    wire carry_reset;          // 计数器重置信号
    
    // 输出赋值
    assign clk_out = clk_out_r;
    
    // 前缀加法器信号
    wire [7:0] p_gen;          // 生成信号
    wire [7:0] p_prop;         // 传播信号
    wire [7:0] carry;          // 进位信号
    
    // 计数器是否需要重置的判断
    assign carry_reset = (counter_r >= half_div_r - 1'b1);
    
    // 阶段1: 捕获并处理分频参数
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            div_ratio_r <= 8'd0;
            half_div_r  <= 8'd0;
        end else begin
            div_ratio_r <= div_ratio;
            half_div_r  <= {1'b0, div_ratio_r[7:1]}; // 计算半分频值
        end
    end
    
    // 前缀加法器实现 - 第一级：生成P和G信号
    assign p_gen[0] = counter_r[0] & incr_value[0];
    assign p_prop[0] = counter_r[0] ^ incr_value[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_pg_signals
            assign p_gen[i] = counter_r[i] & incr_value[i];
            assign p_prop[i] = counter_r[i] ^ incr_value[i];
        end
    endgenerate
    
    // 前缀加法器实现 - 第二级：计算进位信号
    assign carry[0] = p_gen[0];
    
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_carry
            assign carry[i] = p_gen[i] | (p_prop[i] & carry[i-1]);
        end
    endgenerate
    
    // 前缀加法器实现 - 第三级：计算下一个计数器值
    assign next_counter[0] = p_prop[0];
    
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_sum
            assign next_counter[i] = p_prop[i] ^ carry[i-1];
        end
    endgenerate
    
    // 阶段2: 计数与时钟生成控制
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            counter_r <= 8'd0;
            clk_out_r <= 1'b0;
        end else begin
            if (carry_reset) begin
                counter_r <= 8'd0;
                clk_out_r <= ~clk_out_r;  // 翻转时钟
            end else begin
                counter_r <= next_counter; // 使用并行前缀加法器结果
            end
        end
    end

endmodule