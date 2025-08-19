//SystemVerilog
module timeout_parity #(
    parameter TIMEOUT = 100
)(
    input clk, rst,
    input data_valid,
    input [15:0] data,
    output reg parity,
    output reg timeout
);

reg [$clog2(TIMEOUT)-1:0] counter;
wire [$clog2(TIMEOUT)-1:0] next_counter;
wire [$clog2(TIMEOUT)-1:0] timeout_value = TIMEOUT - 1;

// 先行借位减法器实现
wire [$clog2(TIMEOUT):0] borrow;
wire [$clog2(TIMEOUT)-1:0] diff;
reg timeout_internal; // 将timeout信号的计算移到寄存器前

assign borrow[0] = 1'b0;
genvar i;
generate
    for (i = 0; i < $clog2(TIMEOUT); i = i + 1) begin: SUB_GEN
        assign diff[i] = counter[i] ^ timeout_value[i] ^ borrow[i];
        assign borrow[i+1] = (~counter[i] & timeout_value[i]) | 
                           ((~counter[i] | timeout_value[i]) & borrow[i]);
    end
endgenerate

assign next_counter = (data_valid) ? 0 : 
                     (borrow[$clog2(TIMEOUT)]) ? counter + 1 : 0;

// 先计算出组合逻辑结果
wire parity_next = ^data;
wire timeout_next = borrow[$clog2(TIMEOUT)] & ~data_valid;

always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
        timeout_internal <= 0;
    end else begin
        if (data_valid) begin
            counter <= 0;
            timeout_internal <= 0;
        end else begin
            counter <= next_counter;
            timeout_internal <= borrow[$clog2(TIMEOUT)];
        end
    end
end

// 将输出寄存器分离，放在组合逻辑后面
always @(posedge clk) begin
    if (rst) begin
        parity <= 0;
        timeout <= 0;
    end else begin
        if (data_valid) begin
            parity <= parity_next;
        end
        timeout <= timeout_next;
    end
end

endmodule