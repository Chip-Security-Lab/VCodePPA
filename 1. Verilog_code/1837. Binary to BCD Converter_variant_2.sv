//SystemVerilog
// 顶层模块
module bin2bcd_converter #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3
)(
    input  wire [BIN_WIDTH-1:0] binary_in,
    output wire [DIGITS*4-1:0]  bcd_out
);
    // 内部连接信号
    wire [DIGITS*4-1:0] shift_result [BIN_WIDTH:0];
    
    // 初始化第一个寄存器
    assign shift_result[BIN_WIDTH] = {DIGITS*4{1'b0}};
    
    // 实例化位移和调整单元
    genvar i;
    generate
        for (i = 0; i < BIN_WIDTH; i = i + 1) begin : shift_adjust_stages
            shift_adjust_unit #(
                .DIGITS(DIGITS)
            ) shift_adjust_inst (
                .current_bcd(shift_result[BIN_WIDTH-i]),
                .binary_bit(binary_in[BIN_WIDTH-1-i]),
                .next_bcd(shift_result[BIN_WIDTH-i-1])
            );
        end
    endgenerate
    
    // 连接最终输出
    assign bcd_out = shift_result[0];
    
endmodule

// 位移和调整单元子模块
module shift_adjust_unit #(
    parameter DIGITS = 3
)(
    input  wire [DIGITS*4-1:0] current_bcd,
    input  wire                binary_bit,
    output wire [DIGITS*4-1:0] next_bcd
);
    wire [DIGITS*4-1:0] shifted_bcd;
    wire [DIGITS*4-1:0] adjusted_bcd;
    
    // 左移一位并插入二进制位
    assign shifted_bcd = {current_bcd[DIGITS*4-2:0], binary_bit};
    
    // 实例化调整单元
    bcd_adjuster #(
        .DIGITS(DIGITS)
    ) adjuster_inst (
        .bcd_in(shifted_bcd),
        .bcd_out(adjusted_bcd)
    );
    
    // 连接输出
    assign next_bcd = adjusted_bcd;
    
endmodule

// BCD调整器子模块
module bcd_adjuster #(
    parameter DIGITS = 3
)(
    input  wire [DIGITS*4-1:0] bcd_in,
    output wire [DIGITS*4-1:0] bcd_out
);
    // BCD调整逻辑（并行处理每个数字）
    genvar j;
    generate
        for (j = 0; j < DIGITS; j = j + 1) begin : digit_adjusters
            digit_adjuster digit_adj_inst (
                .digit_in(bcd_in[j*4 +: 4]),
                .digit_out(bcd_out[j*4 +: 4])
            );
        end
    endgenerate
    
endmodule

// 单个数字调整器子模块
module digit_adjuster (
    input  wire [3:0] digit_in,
    output reg  [3:0] digit_out
);
    // 使用always块替代条件运算符，使用if-else结构
    always @(*) begin
        if (digit_in > 4'd4) begin
            digit_out = digit_in + 4'd3;
        end else begin
            digit_out = digit_in;
        end
    end
    
endmodule