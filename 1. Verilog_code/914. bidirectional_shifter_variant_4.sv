//SystemVerilog
module bidirectional_shifter(
    input clk,
    input rst_n,
    
    // 输入数据接口 - Valid-Ready握手协议
    input [31:0] data_in,
    input [4:0] shift_amount_in,
    input direction_in,  // 0: left, 1: right
    input valid_in,      // 表示输入数据有效
    output reg ready_in, // 表示模块准备接收新数据
    
    // 输出数据接口 - Valid-Ready握手协议
    output reg [31:0] result_out,
    output reg valid_out,    // 表示输出数据有效
    input ready_out          // 表示下游模块准备接收数据
);
    // 内部寄存器
    reg [31:0] data;
    reg [4:0] shift_amount;
    reg direction;
    reg processing;
    
    // 移位器输出
    wire [31:0] shift_result;
    
    // 握手控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;  // 复位后准备接收数据
            valid_out <= 1'b0; // 复位后没有有效输出
            processing <= 1'b0;
            data <= 32'b0;
            shift_amount <= 5'b0;
            direction <= 1'b0;
            result_out <= 32'b0;
        end else begin
            // 输入握手逻辑
            if (valid_in && ready_in) begin
                // 接收新数据
                data <= data_in;
                shift_amount <= shift_amount_in;
                direction <= direction_in;
                processing <= 1'b1;
                ready_in <= 1'b0;  // 停止接收新数据
            end
            
            // 输出握手逻辑
            if (processing) begin
                valid_out <= 1'b1;  // 设置输出有效
                result_out <= shift_result;
                processing <= 1'b0; // 处理完成
            end
            
            // 当下游模块接收数据后
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;  // 清除输出有效信号
                ready_in <= 1'b1;   // 准备接收下一个数据
            end
        end
    end
    
    // 声明内部信号
    wire [31:0] left_shift_result;
    wire [31:0] right_shift_result;
    
    // 左移桶形移位器实现 - 使用流水线以改善PPA
    wire [31:0] left_stage1, left_stage2, left_stage3, left_stage4, left_stage5;
    
    // 第一级: 移位0或1位
    assign left_stage1 = shift_amount[0] ? {data[30:0], 1'b0} : data;
    
    // 第二级: 移位0或2位
    assign left_stage2 = shift_amount[1] ? {left_stage1[29:0], 2'b00} : left_stage1;
    
    // 第三级: 移位0或4位
    assign left_stage3 = shift_amount[2] ? {left_stage2[27:0], 4'b0000} : left_stage2;
    
    // 第四级: 移位0或8位
    assign left_stage4 = shift_amount[3] ? {left_stage3[23:0], 8'b00000000} : left_stage3;
    
    // 第五级: 移位0或16位
    assign left_stage5 = shift_amount[4] ? {left_stage4[15:0], 16'b0000000000000000} : left_stage4;
    
    assign left_shift_result = left_stage5;
    
    // 右移桶形移位器实现
    wire [31:0] right_stage1, right_stage2, right_stage3, right_stage4, right_stage5;
    
    // 第一级: 移位0或1位
    assign right_stage1 = shift_amount[0] ? {1'b0, data[31:1]} : data;
    
    // 第二级: 移位0或2位
    assign right_stage2 = shift_amount[1] ? {2'b00, right_stage1[31:2]} : right_stage1;
    
    // 第三级: 移位0或4位
    assign right_stage3 = shift_amount[2] ? {4'b0000, right_stage2[31:4]} : right_stage2;
    
    // 第四级: 移位0或8位
    assign right_stage4 = shift_amount[3] ? {8'b00000000, right_stage3[31:8]} : right_stage3;
    
    // 第五级: 移位0或16位
    assign right_stage5 = shift_amount[4] ? {16'b0000000000000000, right_stage4[31:16]} : right_stage4;
    
    assign right_shift_result = right_stage5;
    
    // 根据方向选择最终结果
    assign shift_result = direction ? right_shift_result : left_shift_result;
    
endmodule