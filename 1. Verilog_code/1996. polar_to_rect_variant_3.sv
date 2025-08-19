//SystemVerilog
// Top-level module: polar_to_rect
// Function: Converts polar coordinates (magnitude, angle) to rectangular coordinates (x_out, y_out)
// using LUT-based sine and cosine for efficient hardware implementation.

module polar_to_rect #(
    parameter WIDTH = 16,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] magnitude,
    input  wire [WIDTH-1:0] angle, // 0-255 表示 0-2π
    output wire [WIDTH-1:0] x_out,
    output wire [WIDTH-1:0] y_out
);

    wire signed [WIDTH-1:0] cos_val_wire;
    wire signed [WIDTH-1:0] sin_val_wire;
    wire [WIDTH-1:0] lut_index_wire;

    angle_to_index #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_angle_to_index (
        .angle(angle),
        .index(lut_index_wire)
    );

    trig_lut_rect_calc #(
        .WIDTH(WIDTH),
        .LUT_SIZE(LUT_SIZE)
    ) u_trig_lut_rect_calc (
        .magnitude(magnitude),
        .index(lut_index_wire),
        .x_out(x_out),
        .y_out(y_out)
    );

endmodule

// -----------------------------------------------------------------------------
// 子模块: angle_to_index
// 功能: 角度值映射到LUT索引
// -----------------------------------------------------------------------------
module angle_to_index #(
    parameter WIDTH = 16,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] angle,  // 0-255 表示 0-2π
    output wire [WIDTH-1:0] index   // LUT 索引
);
    assign index = (angle * LUT_SIZE) >> 8;
endmodule

// -----------------------------------------------------------------------------
// 子模块: trig_lut_rect_calc
// 功能: 合并正弦/余弦LUT和直角坐标计算
// -----------------------------------------------------------------------------
module trig_lut_rect_calc #(
    parameter WIDTH = 16,
    parameter LUT_SIZE = 16
)(
    input  wire [WIDTH-1:0] magnitude,
    input  wire [WIDTH-1:0] index,
    output reg  [WIDTH-1:0] x_out,
    output reg  [WIDTH-1:0] y_out
);

    reg signed [WIDTH-1:0] cos_lut [0:LUT_SIZE-1];
    reg signed [WIDTH-1:0] sin_lut [0:LUT_SIZE-1];

    reg signed [WIDTH-1:0] cos_val_reg;
    reg signed [WIDTH-1:0] sin_val_reg;

    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            cos_lut[i] = $cos(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
            sin_lut[i] = $sin(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
        end
    end

    always @* begin
        cos_val_reg = cos_lut[index];
        sin_val_reg = sin_lut[index];
        x_out = (magnitude * cos_val_reg) >>> (WIDTH-2);
        y_out = (magnitude * sin_val_reg) >>> (WIDTH-2);
    end

endmodule