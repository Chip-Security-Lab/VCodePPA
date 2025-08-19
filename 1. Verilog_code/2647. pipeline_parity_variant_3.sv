//SystemVerilog
module pipeline_parity (
    input clk,
    input valid,
    output reg ready,
    input [63:0] data,
    output reg parity
);
reg [63:0] data_stage1, data_stage2;
reg parity_int;

// Internal signal to manage handshake
reg req, ack;

always @(posedge clk) begin
    // Valid-Ready handshake logic
    if (valid && !ready) begin
        req <= 1'b1; // Request data
    end else begin
        req <= 1'b0; // No request
    end

    // Stage 1: 分割数据
    if (req) begin
        data_stage1 <= data;
        ready <= 1'b1; // Indicate ready to receive
    end else begin
        ready <= 1'b0; // Not ready if no request
    end

    // Stage 2: 计算中间校验
    if (req) begin
        parity_int <= ^data_stage1;
    end

    // Stage 3: 最终输出
    parity <= parity_int;
end
endmodule