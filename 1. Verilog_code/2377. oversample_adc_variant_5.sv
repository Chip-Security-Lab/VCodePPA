//SystemVerilog
module oversample_adc (
    input wire clk,
    input wire rst_n,
    input wire adc_in,
    input wire valid_in,
    output wire valid_out,
    output reg [7:0] adc_out
);

    // 优化输入处理
    wire adc_bit_in = adc_in;
    wire input_valid = valid_in;
    
    // Stage 1: 累加器部分
    reg [2:0] sum_stage1;
    reg valid_stage1;
    
    // 比较逻辑优化 - 使用位操作代替比较器
    wire sum_at_max = (sum_stage1 == 3'b111);
    wire [2:0] next_sum = valid_in ? (sum_at_max ? 3'b000 : sum_stage1 + adc_bit_in) : sum_stage1;
    
    // Stage 2: 计算和传输部分
    reg [2:0] sum_stage2;
    reg sum_full_stage2;
    reg valid_stage2;
    
    // 使用直接比较代替位操作&运算符
    wire sum_is_full = (next_sum == 3'b111);
    
    // Stage 1: 累加采样值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage1 <= 3'b000;
            valid_stage1 <= 1'b0;
        end else begin
            sum_stage1 <= next_sum;
            valid_stage1 <= input_valid;
        end
    end
    
    // Stage 2: 检查累加值并准备输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= 3'b000;
            sum_full_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            sum_stage2 <= sum_stage1;
            sum_full_stage2 <= sum_is_full;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 优化输出生成逻辑
    wire gen_output = valid_stage2 && sum_full_stage2;
    // 使用移位操作代替连接操作
    wire [7:0] next_adc_out = gen_output ? (sum_stage2 << 5) : adc_out;
    
    // Stage 3: 生成最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adc_out <= 8'b0;
        end else begin
            adc_out <= next_adc_out;
        end
    end
    
    // 输出有效信号
    assign valid_out = gen_output;

endmodule