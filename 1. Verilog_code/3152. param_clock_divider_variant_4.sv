//SystemVerilog
module param_clock_divider #(
    parameter DIVISOR = 10
)(
    input wire clock_i,
    input wire reset_i,
    output reg clock_o
);
    // 计数器位宽
    localparam COUNT_WIDTH = $clog2(DIVISOR);
    
    // 第一级流水线寄存器 - 计数和比较
    reg [COUNT_WIDTH-1:0] count_stage1;
    reg count_max_stage1;
    
    // 第二级流水线寄存器 - 输出控制
    reg count_max_stage2;
    reg clock_toggle;
    
    // 借位减法器信号
    reg [COUNT_WIDTH-1:0] borrow;
    reg [COUNT_WIDTH-1:0] diff;
    reg [COUNT_WIDTH-1:0] target_val;
    
    // 第一级流水线 - 计数逻辑（使用借位减法器算法）
    always @(posedge clock_i) begin
        if (reset_i) begin
            count_stage1 <= 0;
            count_max_stage1 <= 0;
            target_val <= DIVISOR - 1;
        end else begin
            // 借位减法器实现
            {borrow[0], diff[0]} <= {1'b0, target_val[0]} - {1'b0, count_stage1[0]};
            
            for (int i = 1; i < COUNT_WIDTH; i++) begin
                {borrow[i], diff[i]} <= {1'b0, target_val[i]} - {1'b0, count_stage1[i]} - borrow[i-1];
            end
            
            // 检查是否达到最大计数
            if (diff == 0) begin
                count_stage1 <= 0;
                count_max_stage1 <= 1;
            end else begin
                count_stage1 <= count_stage1 + 1;
                count_max_stage1 <= 0;
            end
        end
    end
    
    // 第二级流水线 - 输出生成
    always @(posedge clock_i) begin
        if (reset_i) begin
            count_max_stage2 <= 0;
            clock_toggle <= 0;
            clock_o <= 0;
        end else begin
            // 传递计数最大值标志
            count_max_stage2 <= count_max_stage1;
            
            // 处理时钟翻转
            if (count_max_stage2) begin
                clock_toggle <= ~clock_toggle;
            end
            
            // 输出时钟信号
            clock_o <= clock_toggle;
        end
    end
endmodule