//SystemVerilog
module ArithEncoder #(PREC=8) (
    input clk, rst_n,
    input [7:0] data,
    output reg [PREC-1:0] code
);
    reg [PREC-1:0] low;
    reg [PREC+7:0] range;  // 加宽范围以提高精度
    reg [15:0] scaled_data; // 预计算的乘积

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            low <= 0;
            range <= 255;
            code <= 0;
        end else begin
            // 先计算乘积，避免多次计算
            scaled_data <= range[7:0] * data;
            
            // 优化计算顺序，防止时序问题
            range <= {8'b0, range[7:0]} * data;
            
            // 使用减法操作而不是减法+乘法组合
            low <= low + (range - {8'b0, scaled_data[15:8]});
            
            // 直接从low赋值给code
            code <= low;
        end
    end
endmodule