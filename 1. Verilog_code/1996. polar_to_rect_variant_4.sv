//SystemVerilog
module polar_to_rect #(parameter WIDTH=16, LUT_SIZE=16)(
    input wire [WIDTH-1:0] magnitude,
    input wire [WIDTH-1:0] angle, // 0-255表示0-2π
    output reg [WIDTH-1:0] x_out,
    output reg [WIDTH-1:0] y_out
);
    reg signed [WIDTH-1:0] cos_lut [0:LUT_SIZE-1];
    reg signed [WIDTH-1:0] sin_lut [0:LUT_SIZE-1];
    reg [WIDTH-1:0] lut_index;

    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            cos_lut[i] = $cos(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
            sin_lut[i] = $sin(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
        end
    end

    // 优化后的桶形移位器，用于右移
    function [WIDTH-1:0] optimized_barrel_shifter_right;
        input [2*WIDTH-1:0] value;
        input integer shift_amt;
        begin
            optimized_barrel_shifter_right = value >> shift_amt;
        end
    endfunction

    // 优化后的桶形移位器，用于右移8位以内
    function [WIDTH-1:0] optimized_barrel_shifter_right8;
        input [WIDTH-1:0] value;
        input [3:0] shift_amt;
        begin
            optimized_barrel_shifter_right8 = value >> shift_amt;
        end
    endfunction

    always @* begin
        // 优化的索引计算：只需截取高位，无需乘法和移位链
        lut_index = angle[7:8-$clog2(LUT_SIZE)];
        
        // 优化的乘法和移位逻辑
        x_out = optimized_barrel_shifter_right($signed(magnitude) * $signed(cos_lut[lut_index]), WIDTH-2);
        y_out = optimized_barrel_shifter_right($signed(magnitude) * $signed(sin_lut[lut_index]), WIDTH-2);
    end
endmodule