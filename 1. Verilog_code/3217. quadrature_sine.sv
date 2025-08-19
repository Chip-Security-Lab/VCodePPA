module quadrature_sine(
    input clk,
    input reset,
    input [7:0] freq_ctrl,
    output reg [7:0] sine,
    output reg [7:0] cosine
);
    reg [7:0] phase;
    reg [7:0] sin_lut [0:7];
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd218;
        sin_lut[2] = 8'd255; sin_lut[3] = 8'd218;
        sin_lut[4] = 8'd128; sin_lut[5] = 8'd37;
        sin_lut[6] = 8'd0;   sin_lut[7] = 8'd37;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            phase <= 8'd0;
            sine <= 8'd128;
            cosine <= 8'd255;
        end else begin
            phase <= phase + freq_ctrl;
            sine <= sin_lut[phase[7:5]];
            cosine <= sin_lut[(phase[7:5] + 3'd2) % 8];
        end
    end
endmodule