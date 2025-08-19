//SystemVerilog
module BidirectionalPISO #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire load,
    input wire left_right,
    input wire [WIDTH-1:0] parallel_in,
    output wire serial_out
);
    // 内部连线
    wire [WIDTH-1:0] shift_buffer_out;
    wire pre_serial_out;
    
    // 实例化子模块
    ShiftRegister #(
        .WIDTH(WIDTH)
    ) shift_reg_inst (
        .clk(clk),
        .load(load),
        .left_right(left_right),
        .parallel_in(parallel_in),
        .buffer_out(shift_buffer_out)
    );
    
    OptimizedOutputSelector #(
        .WIDTH(WIDTH)
    ) out_sel_inst (
        .clk(clk),
        .left_right(left_right),
        .buffer_in(shift_buffer_out),
        .pre_serial_out(pre_serial_out)
    );
    
    // 输出寄存器移至顶层模块，减少关键路径
    reg final_out_reg;
    always @(posedge clk) begin
        final_out_reg <= pre_serial_out;
    end
    
    assign serial_out = final_out_reg;
endmodule

// 移位寄存器子模块，处理加载和移位逻辑
module ShiftRegister #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire load,
    input wire left_right,
    input wire [WIDTH-1:0] parallel_in,
    output reg [WIDTH-1:0] buffer_out
);
    always @(posedge clk) begin
        if (load)
            buffer_out <= parallel_in;
        else if (left_right)
            buffer_out <= {buffer_out[WIDTH-2:0], 1'b0};
        else
            buffer_out <= {1'b0, buffer_out[WIDTH-1:1]};
    end
endmodule

// 优化的输出选择器子模块，移除寄存器以减少延迟
module OptimizedOutputSelector #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire left_right,
    input wire [WIDTH-1:0] buffer_in,
    output wire pre_serial_out
);
    // 直接选择输出位，无寄存器
    assign pre_serial_out = left_right ? buffer_in[WIDTH-1] : buffer_in[0];
endmodule