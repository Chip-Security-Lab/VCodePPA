//SystemVerilog
module pipeline_parity (
    input clk,
    input [63:0] data,
    output reg parity
);

// Internal registers
reg [63:0] data_stage1;
reg parity_int;

// Always block for data staging
always @(posedge clk) begin
    // Stage 1: 分割数据
    data_stage1 <= data;
end

// Always block for parity calculation
always @(posedge clk) begin
    // Stage 2: 计算中间校验
    parity_int <= ^data_stage1;
end

// Always block for final output
always @(posedge clk) begin
    // Stage 3: 最终输出
    parity <= parity_int;
end

endmodule