//SystemVerilog
module parity_checker_req_ack (
    input clk, rst_n,
    input [15:0] data,
    input req,          // 请求信号
    output reg ack,     // 应答信号
    output reg parity
);
    wire calc_parity = ~^data; // 偶校验
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity <= 1'b0;
            ack <= 1'b0; // 复位时应答信号为低
        end else begin
            if (req) begin
                parity <= calc_parity; // 计算校验
                ack <= 1'b1; // 发送应答
            end else begin
                ack <= 1'b0; // 无请求时应答信号为低
            end
        end
    end
endmodule