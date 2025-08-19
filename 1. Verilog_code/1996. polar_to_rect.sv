module polar_to_rect #(parameter WIDTH=16, LUT_SIZE=16)(
    input wire [WIDTH-1:0] magnitude,
    input wire [WIDTH-1:0] angle, // 0-255表示0-2π
    output reg [WIDTH-1:0] x_out,
    output reg [WIDTH-1:0] y_out
);
    reg signed [WIDTH-1:0] cos_lut [0:LUT_SIZE-1];
    reg signed [WIDTH-1:0] sin_lut [0:LUT_SIZE-1];
    reg [WIDTH-1:0] idx;
    
    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            // 简化的查找表，实际应用中使用精确值
            cos_lut[i] = $cos(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
            sin_lut[i] = $sin(2.0*3.14159*i/LUT_SIZE) * (1 << (WIDTH-2));
        end
    end
    
    always @* begin
        idx = (angle * LUT_SIZE) >> 8; // 映射到查找表索引
        x_out = (magnitude * cos_lut[idx]) >> (WIDTH-2);
        y_out = (magnitude * sin_lut[idx]) >> (WIDTH-2);
    end
endmodule