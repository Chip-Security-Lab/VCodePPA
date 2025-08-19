module gamma_correction_codec (
    input clk, enable, reset,
    input [7:0] pixel_in,
    input [2:0] gamma_factor,
    output reg [7:0] pixel_out
);
    reg [15:0] gamma_lut [0:7][0:255];
    integer g, i;
    
    // 初始化查找表
    initial begin
        for (g = 0; g < 8; g = g + 1)
            for (i = 0; i < 256; i = i + 1)
                gamma_lut[g][i] = i * (g + 1);
    end
    
    always @(posedge clk) begin
        if (reset)
            pixel_out <= 8'd0;
        else if (enable)
            pixel_out <= gamma_lut[gamma_factor][pixel_in][7:0];
    end
endmodule