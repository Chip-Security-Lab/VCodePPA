//SystemVerilog
// 顶层模块
module GatedClockShift #(
    parameter BITS = 8
) (
    input gclk,  // 门控时钟
    input en, 
    input s_in,
    output [BITS-1:0] q
);
    // 内部连线
    wire shift_clk;
    
    // 实例化时钟门控模块
    ClockGate u_clock_gate (
        .clk_in(gclk),
        .enable(en),
        .clk_out(shift_clk)
    );
    
    // 实例化移位寄存器模块
    ShiftRegister #(
        .WIDTH(BITS)
    ) u_shift_register (
        .clk(shift_clk),
        .data_in(s_in),
        .data_out(q)
    );
    
endmodule

// 时钟门控模块
module ClockGate (
    input clk_in,
    input enable,
    output clk_out
);
    assign clk_out = clk_in & enable;
    
endmodule

// 移位寄存器模块
module ShiftRegister #(
    parameter WIDTH = 8
) (
    input clk,
    input data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        data_out <= {data_out[WIDTH-2:0], data_in};
    end
    
endmodule