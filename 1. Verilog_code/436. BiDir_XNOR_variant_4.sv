//SystemVerilog
`timescale 1ns / 1ps

// 顶层模块
module BiDir_XNOR(
    inout [7:0] bus_a, bus_b,
    input dir,
    output [7:0] result
);
    // 内部连线声明
    wire [7:0] xnor_result;
    wire [7:0] bus_a_drive, bus_b_drive;
    
    // 实例化XNOR运算子模块
    XNOR_Calculator xnor_calc (
        .in_a(bus_a),
        .in_b(bus_b),
        .result(xnor_result)
    );
    
    // 实例化总线驱动控制子模块
    Bus_Driver bus_driver (
        .xnor_data(xnor_result),
        .direction(dir),
        .bus_a_out(bus_a_drive),
        .bus_b_out(bus_b_drive)
    );
    
    // 输出分配
    assign bus_a = bus_a_drive;
    assign bus_b = bus_b_drive;
    assign result = bus_a;
    
endmodule

// XNOR计算子模块
module XNOR_Calculator(
    input [7:0] in_a, in_b,
    output [7:0] result
);
    // XNOR逻辑运算
    assign result = ~(in_a ^ in_b);
endmodule

// 总线驱动控制子模块
module Bus_Driver(
    input [7:0] xnor_data,
    input direction,
    output [7:0] bus_a_out, bus_b_out
);
    // 方向控制逻辑
    reg [7:0] a_drive, b_drive;
    
    always @(*) begin
        if (direction) begin
            a_drive = xnor_data;
            b_drive = 8'hzz;
        end else begin
            a_drive = 8'hzz;
            b_drive = xnor_data;
        end
    end
    
    // 输出驱动分配
    assign bus_a_out = a_drive;
    assign bus_b_out = b_drive;
endmodule