//SystemVerilog
module shift_add_mult #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    input valid_in,
    output reg valid_out,
    output reg [2*WIDTH-1:0] product
);
    // 流水线级数
    localparam STAGES = 3;
    
    // 数据路径流水线寄存器
    reg [WIDTH-1:0] multiplier_stage1, multiplier_stage2;
    reg [2*WIDTH-1:0] accum_stage1, accum_stage2, accum_stage3;
    reg [2*WIDTH-1:0] shifted_multiplicand_stage1, shifted_multiplicand_stage2;
    
    // 控制信号流水线寄存器
    reg [$clog2(WIDTH):0] bit_count_stage1, bit_count_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg compute_done_stage1, compute_done_stage2;
    
    // 从COMPUTE状态分离出处理逻辑，转换为纯流水线架构
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位所有流水线寄存器
            multiplier_stage1 <= 0;
            multiplier_stage2 <= 0;
            
            accum_stage1 <= 0;
            accum_stage2 <= 0;
            accum_stage3 <= 0;
            
            shifted_multiplicand_stage1 <= 0;
            shifted_multiplicand_stage2 <= 0;
            
            bit_count_stage1 <= 0;
            bit_count_stage2 <= 0;
            
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_stage3 <= 0;
            
            compute_done_stage1 <= 0;
            compute_done_stage2 <= 0;
            
            valid_out <= 0;
            product <= 0;
        end else begin
            // 第一级流水线 - 初始化与位操作准备
            if (valid_in) begin
                // 启动新计算
                multiplier_stage1 <= b;
                shifted_multiplicand_stage1 <= {{WIDTH{1'b0}}, a};
                accum_stage1 <= 0;
                bit_count_stage1 <= 0;
                valid_stage1 <= 1;
                compute_done_stage1 <= 0;
            end else if (valid_stage1 && !compute_done_stage1) begin
                // 继续计算
                // 计算部分积并保存到累加器
                accum_stage1 <= accum_stage1 + ({2*WIDTH{multiplier_stage1[0]}} & shifted_multiplicand_stage1);
                multiplier_stage1 <= multiplier_stage1 >> 1;
                shifted_multiplicand_stage1 <= shifted_multiplicand_stage1 << 1;
                bit_count_stage1 <= bit_count_stage1 + 1'b1;
                
                // 检查是否完成所有位计算
                if (bit_count_stage1 == WIDTH-1)
                    compute_done_stage1 <= 1;
            end
            
            // 第二级流水线 - 继续位操作与累加
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                multiplier_stage2 <= multiplier_stage1;
                shifted_multiplicand_stage2 <= shifted_multiplicand_stage1;
                accum_stage2 <= accum_stage1;
                bit_count_stage2 <= bit_count_stage1;
                compute_done_stage2 <= compute_done_stage1;
            end
            
            // 第三级流水线 - 准备输出结果
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                accum_stage3 <= accum_stage2;
            end
            
            // 输出级
            valid_out <= valid_stage3 && compute_done_stage2;
            if (valid_stage3 && compute_done_stage2) begin
                product <= accum_stage3;
            end
        end
    end
endmodule