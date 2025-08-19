module pipeline_parity (
    input clk,
    input [63:0] data,
    output reg parity
);
reg [63:0] data_stage1, data_stage2;
reg parity_int;

always @(posedge clk) begin
    // Stage 1: 分割数据
    data_stage1 <= data;
    
    // Stage 2: 计算中间校验
    parity_int <= ^data_stage1;
    
    // Stage 3: 最终输出
    parity <= parity_int;
end
endmodule