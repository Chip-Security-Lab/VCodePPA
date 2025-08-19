//SystemVerilog
module pipeline_parity_req_ack (
    input clk,
    input req,
    output reg ack,
    input [63:0] data,
    output reg parity
);

reg [63:0] data_stage1;
reg parity_int;
reg req_d;

always @(posedge clk) begin
    // 合并请求和数据锁存
    {req_d, data_stage1} <= {req, req ? data : data_stage1};
    
    // 优化校验计算
    parity_int <= ^data_stage1;
    parity <= parity_int;
    
    // 简化应答逻辑
    ack <= req_d;
end

endmodule