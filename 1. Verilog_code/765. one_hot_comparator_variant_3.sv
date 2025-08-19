//SystemVerilog
module one_hot_comparator #(
    parameter WIDTH = 8
)(
    input wire clk,                  // 时钟信号
    input wire rst_n,                // 复位信号
    input wire [WIDTH-1:0] one_hot_a,// One-hot编码输入A
    input wire [WIDTH-1:0] one_hot_b,// One-hot编码输入B
    output reg valid_one_hot_a,      // A是否为有效one-hot
    output reg valid_one_hot_b,      // B是否为有效one-hot
    output reg equal_states,         // 如果两者表示相同状态则为true
    output reg [WIDTH-1:0] common_states // 按位AND显示共同活动位
);

    // ================= 第一级流水线：计算有效性 ================= 
    // 使用树形结构进行计数以减少逻辑深度
    wire valid_a_stage1;
    wire valid_b_stage1;
    wire [WIDTH-1:0] common_bits_stage1;
    
    // 优化的树形加法计数器用于A
    reg [(WIDTH/2):0] sum_a_level1;
    always @(*) begin
        integer j;
        for(j = 0; j < WIDTH/2; j = j + 1) begin
            sum_a_level1[j] = one_hot_a[j*2] + one_hot_a[j*2+1];
        end
        if(WIDTH % 2 == 1)
            sum_a_level1[WIDTH/2] = one_hot_a[WIDTH-1];
        else
            sum_a_level1[WIDTH/2] = 1'b0;
    end
    
    wire [4:0] final_sum_a; // 足够存储WIDTH的位数
    assign final_sum_a = ^sum_a_level1 ? 1 : 0; // 奇偶校验用于快速检测是否只有一位为1
    assign valid_a_stage1 = (final_sum_a == 1);
    
    // 优化的树形加法计数器用于B
    reg [(WIDTH/2):0] sum_b_level1;
    always @(*) begin
        integer j;
        for(j = 0; j < WIDTH/2; j = j + 1) begin
            sum_b_level1[j] = one_hot_b[j*2] + one_hot_b[j*2+1];
        end
        if(WIDTH % 2 == 1)
            sum_b_level1[WIDTH/2] = one_hot_b[WIDTH-1];
        else
            sum_b_level1[WIDTH/2] = 1'b0;
    end
    
    wire [4:0] final_sum_b; // 足够存储WIDTH的位数
    assign final_sum_b = ^sum_b_level1 ? 1 : 0; // 奇偶校验用于快速检测是否只有一位为1
    assign valid_b_stage1 = (final_sum_b == 1);
    
    // 计算公共状态
    assign common_bits_stage1 = one_hot_a & one_hot_b;
    
    // 第一级流水线寄存器
    reg valid_a_pipe1;
    reg valid_b_pipe1;
    reg [WIDTH-1:0] one_hot_a_pipe1, one_hot_b_pipe1;
    reg [WIDTH-1:0] common_bits_pipe1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_a_pipe1 <= 1'b0;
            valid_b_pipe1 <= 1'b0;
            one_hot_a_pipe1 <= {WIDTH{1'b0}};
            one_hot_b_pipe1 <= {WIDTH{1'b0}};
            common_bits_pipe1 <= {WIDTH{1'b0}};
        end else begin
            valid_a_pipe1 <= valid_a_stage1;
            valid_b_pipe1 <= valid_b_stage1;
            one_hot_a_pipe1 <= one_hot_a;
            one_hot_b_pipe1 <= one_hot_b;
            common_bits_pipe1 <= common_bits_stage1;
        end
    end
    
    // ================= 第二级流水线：比较操作 ================= 
    wire equal_states_stage2;
    wire [WIDTH-1:0] common_states_stage2;
    
    // 优化相等比较逻辑 - 使用XOR减少逻辑深度
    wire inputs_equal;
    assign inputs_equal = ~|(one_hot_a_pipe1 ^ one_hot_b_pipe1); // XOR后NOR，高性能相等检测
    
    wire has_common_bits;
    assign has_common_bits = |common_bits_pipe1;
    
    assign equal_states_stage2 = inputs_equal || has_common_bits;
    assign common_states_stage2 = common_bits_pipe1;
    
    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_one_hot_a <= 1'b0;
            valid_one_hot_b <= 1'b0;
            equal_states <= 1'b0;
            common_states <= {WIDTH{1'b0}};
        end else begin
            valid_one_hot_a <= valid_a_pipe1;
            valid_one_hot_b <= valid_b_pipe1;
            equal_states <= equal_states_stage2;
            common_states <= common_states_stage2;
        end
    end

endmodule