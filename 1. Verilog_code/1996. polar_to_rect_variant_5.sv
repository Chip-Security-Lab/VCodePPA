//SystemVerilog
module polar_to_rect #(parameter WIDTH=16, LUT_SIZE=16)(
    input wire [WIDTH-1:0] magnitude,
    input wire [WIDTH-1:0] angle, // 0-255 represents 0-2π
    output reg [WIDTH-1:0] x_out,
    output reg [WIDTH-1:0] y_out
);
    reg signed [WIDTH-1:0] cos_lut [0:LUT_SIZE-1];
    reg signed [WIDTH-1:0] sin_lut [0:LUT_SIZE-1];
    reg [WIDTH-1:0] lut_index;
    reg signed [WIDTH-1:0] cos_value;
    reg signed [WIDTH-1:0] sin_value;
    reg signed [2*WIDTH-1:0] x_mult_result;
    reg signed [2*WIDTH-1:0] y_mult_result;
    reg signed [WIDTH-1:0] cos_lut_neg;
    reg signed [WIDTH-1:0] sin_lut_neg;
    reg signed [WIDTH-1:0] magnitude_neg;
    reg signed [WIDTH-1:0] x_subtrahend;
    reg signed [WIDTH-1:0] y_subtrahend;

    integer i;
    initial begin
        i = 0;
        while (i < LUT_SIZE) begin
            cos_lut[i] = $cos(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
            sin_lut[i] = $sin(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
            i = i + 1;
        end
    end

    always @* begin
        lut_index = (angle * LUT_SIZE) >> 8;

        cos_value = cos_lut[lut_index];
        sin_value = sin_lut[lut_index];

        cos_lut_neg = ~cos_value + 1'b1;
        sin_lut_neg = ~sin_value + 1'b1;
        magnitude_neg = ~magnitude + 1'b1;

        x_mult_result = $signed(magnitude) * $signed(cos_value);
        y_mult_result = $signed(magnitude) * $signed(sin_value);

        x_subtrahend = (x_mult_result < 0) ? (~(-x_mult_result[2*WIDTH-1:WIDTH-2]) + 1'b1) : x_mult_result[2*WIDTH-1:WIDTH-2];
        y_subtrahend = (y_mult_result < 0) ? (~(-y_mult_result[2*WIDTH-1:WIDTH-2]) + 1'b1) : y_mult_result[2*WIDTH-1:WIDTH-2];

        x_out = (x_mult_result[2*WIDTH-1]) ? ((0) + x_subtrahend) : ((0) + x_subtrahend);
        y_out = (y_mult_result[2*WIDTH-1]) ? ((0) + y_subtrahend) : ((0) + y_subtrahend);
    end
endmodule