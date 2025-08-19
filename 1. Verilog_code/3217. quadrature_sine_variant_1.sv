//SystemVerilog
module quadrature_sine(
    input clk,
    input reset,
    input [7:0] freq_ctrl,
    output reg [7:0] sine,
    output reg [7:0] cosine
);
    reg [7:0] phase;
    reg [7:0] sin_lut [0:7];
    
    // 带状进位加法器信号
    wire [7:0] phase_next;
    wire [7:0] p, g;  // 传播和生成信号
    wire [8:0] c;     // 进位信号，多一位用于溢出检测
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd218;
        sin_lut[2] = 8'd255; sin_lut[3] = 8'd218;
        sin_lut[4] = 8'd128; sin_lut[5] = 8'd37;
        sin_lut[6] = 8'd0;   sin_lut[7] = 8'd37;
    end
    
    // 带状进位加法器(CLA)实现
    // 生成传播(p)和生成(g)信号
    assign p = phase ^ freq_ctrl;
    assign g = phase & freq_ctrl;
    
    // 进位计算
    assign c[0] = 1'b0;  // 初始进位为0
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    
    // 求和
    assign phase_next = p ^ c[7:0];
    
    always @(posedge clk) begin
        if (reset) begin
            phase <= 8'd0;
            sine <= 8'd128;
            cosine <= 8'd255;
        end else begin
            phase <= phase_next;
            sine <= sin_lut[phase_next[7:5]];
            cosine <= sin_lut[(phase_next[7:5] + 3'd2) % 8];
        end
    end
endmodule