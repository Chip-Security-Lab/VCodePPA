//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module ArithmeticRightShift #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input shift_amount,
    output [WIDTH-1:0] data_out
);
    // 内部信号声明
    wire sign_bit;
    wire [WIDTH-1:0] shifted_data;
    
    // 子模块实例化
    SignBitExtractor #(.WIDTH(WIDTH)) sign_extractor (
        .data_in(data_in),
        .sign_bit(sign_bit)
    );
    
    ShiftLogic #(.WIDTH(WIDTH)) shifter (
        .data_in(data_in),
        .shift_amount(shift_amount),
        .sign_bit(sign_bit),
        .shifted_data(shifted_data)
    );
    
    OutputAssignment #(.WIDTH(WIDTH)) output_stage (
        .shifted_data(shifted_data),
        .data_out(data_out)
    );
    
endmodule

// 子模块1: 符号位提取器
module SignBitExtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output reg sign_bit
);
    // 提取符号位
    always @(*) begin
        sign_bit = data_in[WIDTH-1];
    end
endmodule

// 子模块2: 移位逻辑
module ShiftLogic #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input shift_amount,
    input sign_bit,
    output reg [WIDTH-1:0] shifted_data
);
    // 实现移位逻辑
    always @(*) begin
        if (shift_amount) begin
            // 算术右移操作
            shifted_data[WIDTH-2:0] = data_in[WIDTH-1:1];
            shifted_data[WIDTH-1] = sign_bit;
        end else begin
            // 不移位时直接传递输入
            shifted_data = data_in;
        end
    end
endmodule

// 子模块3: 输出赋值
module OutputAssignment #(parameter WIDTH=8) (
    input [WIDTH-1:0] shifted_data,
    output reg [WIDTH-1:0] data_out
);
    // 输出赋值
    always @(*) begin
        data_out = shifted_data;
    end
endmodule