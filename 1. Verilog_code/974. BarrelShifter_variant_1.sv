//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module BarrelShifter #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [3:0] shift_ctrl,
    output [WIDTH-1:0] data_out
);
    // 内部连线
    wire [WIDTH-1:0] stage1_out, stage2_out;
    
    // 第一级移位 - 1位和2位移位
    ShiftStage #(
        .WIDTH(WIDTH),
        .SHIFT_BITS(2)
    ) first_stage (
        .data_in(data_in),
        .shift_amt(shift_ctrl[1:0]),
        .data_out(stage1_out)
    );
    
    // 第二级移位 - 4位和8位移位
    ShiftStage #(
        .WIDTH(WIDTH),
        .SHIFT_BITS(2)
    ) second_stage (
        .data_in(stage1_out),
        .shift_amt(shift_ctrl[3:2]),
        .data_out(stage2_out)
    );
    
    // 输出缓冲
    OutputBuffer #(
        .WIDTH(WIDTH)
    ) output_buf (
        .data_in(stage2_out),
        .data_out(data_out)
    );
endmodule

// 移位级子模块
module ShiftStage #(
    parameter WIDTH = 8,
    parameter SHIFT_BITS = 2
)(
    input [WIDTH-1:0] data_in,
    input [SHIFT_BITS-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] shifted_data;
    
    always @(*) begin
        if (shift_amt == 2'b00) begin
            shifted_data = data_in;
        end
        else if (shift_amt == 2'b01) begin
            shifted_data = data_in << (1 << 0);
        end
        else if (shift_amt == 2'b10) begin
            shifted_data = data_in << (1 << 1);
        end
        else begin
            // shift_amt == 2'b11
            shifted_data = data_in << ((1 << 0) + (1 << 1));
        end
    end
    
    assign data_out = shifted_data;
endmodule

// 输出缓冲子模块
module OutputBuffer #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // 用缓冲器改善驱动能力和时序
    assign data_out = data_in;
endmodule