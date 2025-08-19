//SystemVerilog
module oversample_adc (
    input clk, adc_in,
    output reg [7:0] adc_out
);
    reg [2:0] sum;
    wire [2:0] next_sum;
    
    // 先行进位加法器实现
    wire [2:0] p, g; // 传播和生成信号
    wire [2:0] c;    // 进位信号
    
    // 生成传播(p)和生成(g)信号
    assign p[0] = sum[0];
    assign p[1] = sum[1];
    assign p[2] = sum[2];
    
    assign g[0] = adc_in & sum[0];
    assign g[1] = 0; // 由于只加1位，其他位没有生成信号
    assign g[2] = 0;
    
    // 计算进位
    assign c[0] = adc_in;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    
    // 计算和
    assign next_sum[0] = sum[0] ^ adc_in;
    assign next_sum[1] = sum[1] ^ c[1];
    assign next_sum[2] = sum[2] ^ c[2];
    
    always @(posedge clk) begin
        sum <= next_sum;
        if (&next_sum[2:0]) adc_out <= next_sum[2:0] << 5;
    end
endmodule