//SystemVerilog
module nonlinear_quant #(parameter IN_W=8, OUT_W=4, LUT_SIZE=16) (
    input clk, 
    input [IN_W-1:0] data_in,
    output reg [OUT_W-1:0] quant_out
);
    reg [OUT_W-1:0] lut [0:LUT_SIZE-1];
    integer i;

    initial begin // 示例S型曲线LUT
        i = 0;
        while(i < LUT_SIZE) begin
            lut[i] = ((i*i) >> (IN_W - OUT_W)); // 使用乘法替代幂运算
            i = i + 1;
        end
    end

    always @(posedge clk) 
        quant_out <= lut[data_in[IN_W-1:IN_W-$clog2(LUT_SIZE)]]; // 修正索引方式
endmodule