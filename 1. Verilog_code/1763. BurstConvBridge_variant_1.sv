//SystemVerilog
module BurstConvBridge #(
    parameter MAX_BURST = 16
)(
    input clk, rst_n,
    input [31:0] addr_in,
    input [7:0] burst_len,
    output reg [31:0] addr_out,
    output reg [3:0] sub_burst
);
    // 分割寄存器，减少关键路径长度
    reg [7:0] counter;
    reg burst_exceed_max;
    reg [3:0] next_sub_burst;
    reg [31:0] next_addr;
    reg [7:0] burst_div_max;
    reg [7:0] counter_next;

    // 计算burst是否超过最大值
    always @(*) begin
        burst_exceed_max = burst_len > MAX_BURST;
    end

    // 计算burst除以最大值的商
    always @(*) begin
        burst_div_max = burst_len / MAX_BURST;
    end

    // 计算下一个子burst长度
    always @(*) begin
        if (burst_exceed_max) begin
            next_sub_burst = MAX_BURST;
        end else begin
            next_sub_burst = burst_len[3:0];
        end
    end

    // 计算下一个地址
    always @(*) begin
        if (burst_exceed_max) begin
            next_addr = addr_in + (counter << 2);
        end else begin
            next_addr = addr_in;
        end
    end

    // 计算下一个计数器值
    always @(*) begin
        if (burst_exceed_max) begin
            counter_next = (counter < burst_div_max) ? counter + 8'b1 : 8'b0;
        end else begin
            counter_next = counter;
        end
    end

    // 时序逻辑更新
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            counter <= 8'b0;
            addr_out <= 32'b0;
            sub_burst <= 4'b0;
        end else begin
            counter <= counter_next;
            addr_out <= next_addr;
            sub_burst <= next_sub_burst;
        end
    end
endmodule