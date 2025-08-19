//SystemVerilog
// 顶层模块
module rom_thermometer #(
    parameter N = 8
)(
    input      [2:0] val,
    output     [N-1:0] code
);
    // 热码转换器实例化
    thermometer_encoder #(
        .WIDTH(N)
    ) encoder_inst (
        .binary_input(val),
        .therm_output(code)
    );
endmodule

// 热码编码器子模块
module thermometer_encoder #(
    parameter WIDTH = 8
)(
    input      [2:0] binary_input,
    output reg [WIDTH-1:0] therm_output
);
    // 执行热码转换功能
    // 将二进制输入值转换为热码输出
    always @(*) begin
        // 通过位移和减法生成热码
        therm_output = (1'b1 << binary_input) - 1'b1;
    end
endmodule