//SystemVerilog
//顶层模块
module arithmetic_shift_right (
    input signed [31:0] data_in,
    input [4:0] shift,
    output signed [31:0] data_out
);
    // 内部连线
    wire sign_bit;
    wire [31:0] shift_result;
    
    // 子模块实例化
    sign_extractor sign_ext_inst (
        .data_in(data_in),
        .sign_bit(sign_bit)
    );
    
    shift_processor shift_proc_inst (
        .data_in(data_in),
        .shift_amount(shift),
        .sign_bit(sign_bit),
        .shift_result(shift_result)
    );
    
    output_register out_reg_inst (
        .shift_result(shift_result),
        .data_out(data_out)
    );
    
endmodule

// 提取符号位的子模块
module sign_extractor (
    input signed [31:0] data_in,
    output sign_bit
);
    // 提取符号位用于扩展
    assign sign_bit = data_in[31];
endmodule

// 执行实际移位操作的子模块 - 使用借位减法器算法实现
module shift_processor #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input signed [DATA_WIDTH-1:0] data_in,
    input [SHIFT_WIDTH-1:0] shift_amount,
    input sign_bit,
    output [DATA_WIDTH-1:0] shift_result
);
    // 临时变量
    reg [DATA_WIDTH-1:0] temp_result;
    reg [DATA_WIDTH-1:0] shift_mask;
    reg [DATA_WIDTH-1:0] minuend;
    reg [DATA_WIDTH-1:0] subtrahend;
    reg [DATA_WIDTH:0] borrow; // 多一位存放借位
    
    integer i, j;
    
    always @(*) begin
        // 初始化
        temp_result = data_in;
        
        if (shift_amount > 0) begin
            // 借位减法器实现算术右移
            minuend = temp_result;
            borrow[0] = 1'b0; // 初始无借位
            
            for (i = 0; i < shift_amount; i = i + 1) begin
                // 计算本次移位的掩码
                shift_mask = {{(DATA_WIDTH-1){1'b0}}, 1'b1} << (DATA_WIDTH - 1 - i);
                
                // 根据原始数据生成减数
                subtrahend = {DATA_WIDTH{1'b0}};
                
                // 对每一位执行借位减法
                for (j = 0; j < DATA_WIDTH; j = j + 1) begin
                    // 借位减法计算
                    borrow[j+1] = (~minuend[j] & subtrahend[j]) | 
                                  (~minuend[j] & borrow[j]) | 
                                  (subtrahend[j] & borrow[j]);
                    
                    temp_result[j] = minuend[j] ^ subtrahend[j] ^ borrow[j];
                end
                
                // 符号位扩展
                temp_result = {sign_bit, temp_result[DATA_WIDTH-1:1]};
                minuend = temp_result;
                borrow[0] = 1'b0;
            end
        end
    end
    
    assign shift_result = temp_result;
endmodule

// 输出寄存器处理
module output_register #(
    parameter DATA_WIDTH = 32
)(
    input [DATA_WIDTH-1:0] shift_result,
    output reg signed [DATA_WIDTH-1:0] data_out
);
    // 将结果传递到输出
    // 使用寄存器可以改善时序性能
    always @(*) begin
        data_out = shift_result;
    end
endmodule