//SystemVerilog
// IEEE 1364-2005 Verilog标准
module RevCounterShift #(parameter N=4) (
    input wire clk, 
    input wire up_down, 
    input wire load, 
    input wire [N-1:0] preset,
    output reg [N-1:0] cnt
);

    // 内部信号定义 - 改进命名以反映数据流阶段
    wire [N-1:0] shift_result;       // 移位结果
    wire [N-1:0] shift_up_result;    // 上移结果
    wire [N-1:0] shift_down_result;  // 下移结果
    
    reg [N-1:0] next_cnt;            // 下一个计数值
    reg [N-1:0] shift_stage_reg;     // 增加移位阶段寄存器
    
    // ===== 阶段1: 上移和下移的并行计算 =====
    
    // 上移模式实现 - 循环左移
    assign shift_up_result = {cnt[N-2:0], cnt[N-1]};

    // 下移模式实现 - 使用优化的算法
    // 生成借位信号
    wire [N:0] borrow;
    assign borrow[0] = 1'b0; // 初始借位为0

    // 借位计算模块化，使用生成块
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_borrow_logic
            // 当前位借位计算
            wire is_zero = (cnt[i] == 1'b0);
            assign borrow[i+1] = is_zero ? borrow[i] : 1'b0;
        end
    endgenerate
    
    // 下移结果计算 - 分段处理以减少关键路径长度
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_shift_down
            if (i == 0) begin: first_bit
                assign shift_down_result[i] = cnt[i]; // 第一位特殊处理
            end else begin: other_bits
                assign shift_down_result[i] = borrow[i] ? ~cnt[i] : cnt[i];
            end
        end
    endgenerate
    
    // ===== 阶段2: 移位结果选择 =====
    // 基于上移/下移控制信号选择适当的移位结果
    assign shift_result = up_down ? shift_up_result : shift_down_result;
    
    // ===== 阶段3: 最终计数值确定 =====
    // 根据load信号确定下一个计数值
    always @(*) begin
        next_cnt = load ? preset : shift_stage_reg;
    end
    
    // ===== 流水线寄存器阶段 =====
    // 移位操作结果寄存
    always @(posedge clk) begin
        shift_stage_reg <= shift_result;
    end
    
    // 输出寄存器更新
    always @(posedge clk) begin
        cnt <= next_cnt;
    end

endmodule