//SystemVerilog
// 顶层模块
module gray_code_reg (
    input wire clk,
    input wire reset,
    input wire [7:0] bin_in,
    input wire load,
    input wire convert,
    output wire [7:0] gray_out
);
    
    // 内部信号定义
    wire [7:0] binary_value;
    wire [7:0] gray_value;
    
    // 实例化二进制寄存器模块
    binary_register bin_reg (
        .clk(clk),
        .reset(reset),
        .bin_in(bin_in),
        .load(load),
        .binary_out(binary_value)
    );
    
    // 实例化二进制到格雷码转换器模块，已重定时
    bin_to_gray_converter converter (
        .clk(clk),
        .reset(reset),
        .binary_in(binary_value),
        .convert(convert),
        .gray_out(gray_out)
    );
    
endmodule

// 二进制寄存器模块 - 负责存储二进制值
module binary_register (
    input wire clk,
    input wire reset,
    input wire [7:0] bin_in,
    input wire load,
    output reg [7:0] binary_out
);
    
    always @(posedge clk) begin
        if (reset)
            binary_out <= 8'h00;
        else if (load)
            binary_out <= bin_in;
    end
    
endmodule

// 二进制到格雷码转换器 - 重定时后包含寄存器
module bin_to_gray_converter (
    input wire clk,
    input wire reset,
    input wire [7:0] binary_in,
    input wire convert,
    output reg [7:0] gray_out
);
    
    // 组合逻辑部分
    wire [7:0] gray_value;
    assign gray_value = binary_in ^ {1'b0, binary_in[7:1]};
    
    // 集成了格雷码输出寄存器功能
    always @(posedge clk) begin
        if (reset)
            gray_out <= 8'h00;
        else if (convert)
            gray_out <= gray_value;
    end
    
endmodule