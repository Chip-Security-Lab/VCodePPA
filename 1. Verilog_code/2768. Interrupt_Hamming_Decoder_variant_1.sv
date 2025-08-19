//SystemVerilog
module Interrupt_Hamming_Decoder(
    input clk,
    input [7:0] code_in,
    output reg [3:0] data_out,
    output reg uncorrectable_irq
);
    // 第一级流水线 - 初步计算拆分为更细粒度
    reg [7:0] code_stage1a;
    reg code_parity_stage1a;
    reg [3:0] part_parity1_stage1a;
    reg [3:0] part_parity2_stage1a;
    
    // 第一级后半部分 - 校验位计算拆分
    reg [7:0] code_stage1b;
    reg parity_check_stage1b;
    reg check1_part1_stage1b, check1_part2_stage1b;
    reg check2_part1_stage1b, check2_part2_stage1b;
    
    // 第二级流水线 - 校验和错误检测
    reg [7:0] code_stage2;
    reg parity_check_stage2;
    reg check1_stage2, check2_stage2;
    
    // 第二级后半部分 - 错误状态分析
    reg [7:0] code_stage2b;
    reg [1:0] error_state_stage2b;
    
    // 第三级流水线 - 提取数据和错误状态
    reg [3:0] data_stage3;
    reg [1:0] error_state_stage3;
    
    // 第一级流水线前半部分 - 并行计算校验位部分值
    always @(posedge clk) begin
        // 寄存输入数据
        code_stage1a <= code_in;
        
        // 计算输入数据的奇偶校验
        code_parity_stage1a <= ^code_in;
        
        // 预计算校验位的部分结果，减少单周期逻辑深度
        part_parity1_stage1a <= {code_in[7], code_in[6], code_in[5], code_in[4]};
        part_parity2_stage1a <= {code_in[7], code_in[6], code_in[3], code_in[2]};
    end
    
    // 第一级流水线后半部分 - 完成校验位计算
    always @(posedge clk) begin
        // 传递数据
        code_stage1b <= code_stage1a;
        
        // 计算总体奇偶校验结果
        parity_check_stage1b <= (code_parity_stage1a != 0);
        
        // 拆分校验位1的计算路径
        check1_part1_stage1b <= ^part_parity1_stage1a;
        check1_part2_stage1b <= code_stage1a[0];
        
        // 拆分校验位2的计算路径
        check2_part1_stage1b <= ^part_parity2_stage1a;
        check2_part2_stage1b <= code_stage1a[1];
    end
    
    // 第二级流水线前半部分 - 完成校验结果
    always @(posedge clk) begin
        // 传递数据
        code_stage2 <= code_stage1b;
        parity_check_stage2 <= parity_check_stage1b;
        
        // 完成校验计算，比较结果
        check1_stage2 <= (check1_part1_stage1b != check1_part2_stage1b);
        check2_stage2 <= (check2_part1_stage1b != check2_part2_stage1b);
    end
    
    // 第二级流水线后半部分 - 错误状态分析
    always @(posedge clk) begin
        // 传递数据
        code_stage2b <= code_stage2;
        
        // 根据检测结果确定错误状态
        if (!parity_check_stage2) begin
            error_state_stage2b <= 2'b00; // 无错误
        end else begin
            if (check1_stage2)
                error_state_stage2b <= 2'b01; // 1位错误
            else if (check2_stage2)
                error_state_stage2b <= 2'b10; // 1位错误
            else
                error_state_stage2b <= 2'b11; // 不可纠正错误
        end
    end
    
    // 第三级流水线 - 准备输出
    always @(posedge clk) begin
        // 提取数据
        data_stage3 <= code_stage2b[7:4];
        error_state_stage3 <= error_state_stage2b;
    end
    
    // 最终输出级 - 将处理结果输出
    always @(posedge clk) begin
        data_out <= data_stage3;
        uncorrectable_irq <= (error_state_stage3 == 2'b11);
    end
endmodule