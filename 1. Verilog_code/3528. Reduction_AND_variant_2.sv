//SystemVerilog
module Reduction_AND_Top(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire valid_in,
    output wire ready_out,
    output wire result,
    output wire valid_out,
    input wire ready_in
);
    // 中间信号声明
    wire lower_result;
    wire upper_result;
    wire internal_result;
    
    // 握手信号控制
    reg data_valid;
    reg result_valid;
    wire processing_ready;
    
    // 数据寄存器
    reg [7:0] data_reg;
    
    // 握手逻辑
    assign ready_out = !data_valid || processing_ready;
    assign processing_ready = !result_valid || ready_in;
    assign valid_out = result_valid;
    
    // 数据有效位复位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
        end
    end
    
    // 数据有效位设置逻辑
    always @(posedge clk) begin
        if (rst_n && ready_out && valid_in) begin
            data_valid <= 1'b1;
        end
    end
    
    // 数据有效位清除逻辑
    always @(posedge clk) begin
        if (rst_n && data_valid && processing_ready) begin
            data_valid <= 1'b0;
        end
    end
    
    // 数据寄存逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else if (ready_out && valid_in) begin
            data_reg <= data;
        end
    end
    
    // 结果有效位复位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_valid <= 1'b0;
        end
    end
    
    // 结果有效位设置逻辑
    always @(posedge clk) begin
        if (rst_n && data_valid && processing_ready && !result_valid) begin
            result_valid <= 1'b1;
        end
    end
    
    // 结果有效位清除逻辑
    always @(posedge clk) begin
        if (rst_n && result_valid && ready_in) begin
            result_valid <= 1'b0;
        end
    end
    
    // 结果寄存器
    reg result_reg;
    
    // 结果寄存器复位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 1'b0;
        end
    end
    
    // 结果寄存器更新逻辑
    always @(posedge clk) begin
        if (rst_n && data_valid && processing_ready) begin
            result_reg <= internal_result;
        end
    end
    
    assign result = result_reg;
    
    // 实例化低4位与运算子模块
    Reduction_AND_4bit lower_bits(
        .data(data_reg[3:0]),
        .result(lower_result)
    );
    
    // 实例化高4位与运算子模块
    Reduction_AND_4bit upper_bits(
        .data(data_reg[7:4]),
        .result(upper_result)
    );
    
    // 实例化最终合并子模块
    Final_AND_Stage final_stage(
        .a(lower_result),
        .b(upper_result),
        .result(internal_result)
    );
endmodule

// 4位缩位与运算模块
module Reduction_AND_4bit(
    input [3:0] data,
    output result
);
    // 中间信号声明
    wire stage1_result1;
    wire stage1_result2;
    
    // 第一级2位与运算
    Two_Input_AND and1(
        .a(data[0]),
        .b(data[1]),
        .result(stage1_result1)
    );
    
    // 第一级2位与运算
    Two_Input_AND and2(
        .a(data[2]),
        .b(data[3]),
        .result(stage1_result2)
    );
    
    // 最终合并结果
    Two_Input_AND final_and(
        .a(stage1_result1),
        .b(stage1_result2),
        .result(result)
    );
endmodule

// 2输入与门模块
module Two_Input_AND(
    input a,
    input b,
    output result
);
    assign result = a & b;
endmodule

// 最终合并模块
module Final_AND_Stage(
    input a,
    input b,
    output result
);
    assign result = a & b;
endmodule