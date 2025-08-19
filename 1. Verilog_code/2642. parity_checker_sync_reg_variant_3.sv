//SystemVerilog
module parity_checker_req_ack (
    input clk, rst_n,
    input [15:0] data,
    input req,          // 请求信号，替代valid
    output reg ack,     // 应答信号，替代ready
    output reg parity
);

wire calc_parity = ~^data; // 偶校验
reg data_processed;        // 数据处理状态标志

// 请求-应答握手处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ack <= 1'b0;
        parity <= 1'b0;
        data_processed <= 1'b0;
    end
    else begin
        if (req && !data_processed) begin
            // 接收到新的请求且尚未处理
            parity <= calc_parity;
            ack <= 1'b1;           // 发送应答信号
            data_processed <= 1'b1; // 标记数据已处理
        end
        else if (!req && data_processed) begin
            // 请求被撤销，重置应答和处理状态
            ack <= 1'b0;
            data_processed <= 1'b0;
        end
        else if (!req) begin
            // 无请求时保持应答为低
            ack <= 1'b0;
        end
    end
end

endmodule