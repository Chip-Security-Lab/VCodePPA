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

    integer lut_init_idx;
    initial begin
        for (lut_init_idx = 0; lut_init_idx < LUT_SIZE; lut_init_idx = lut_init_idx + 1) begin
            // Simplified LUT, use accurate values in real applications
            cos_lut[lut_init_idx] = $cos(2.0*3.14159*lut_init_idx/LUT_SIZE) * (1 << (WIDTH-2));
            sin_lut[lut_init_idx] = $sin(2.0*3.14159*lut_init_idx/LUT_SIZE) * (1 << (WIDTH-2));
        end
    end

    always @* begin
        lut_index = (angle * LUT_SIZE) >> 8; // Map angle to LUT index
        x_out = (magnitude * cos_lut[lut_index]) >> (WIDTH-2);
        y_out = (magnitude * sin_lut[lut_index]) >> (WIDTH-2);
    end
endmodule