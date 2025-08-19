//SystemVerilog
module ptp_timestamp #(
    parameter CLOCK_PERIOD_NS = 4
)(
    input wire clk,
    input wire rst,
    input wire pps,
    input wire [63:0] ptp_delay,
    output reg [95:0] tx_timestamp,
    output reg ts_valid
);
    localparam NS_PER_SEC = 1000;
    
    reg [63:0] ns_counter;
    reg [31:0] sub_ns;
    reg pps_d1, pps_d2;
    reg [63:0] ptp_delay_d1;
    wire sub_ns_overflow;
    wire [31:0] next_sub_ns;
    
    // 优化的进位和溢出检测
    assign next_sub_ns = sub_ns + CLOCK_PERIOD_NS;
    assign sub_ns_overflow = (next_sub_ns >= NS_PER_SEC);

    // 输入寄存器前移
    always @(posedge clk) begin
        if (rst) begin
            pps_d1 <= 1'b0;
            pps_d2 <= 1'b0;
            ptp_delay_d1 <= 64'h0;
        end else begin
            pps_d1 <= pps;
            pps_d2 <= pps_d1;
            ptp_delay_d1 <= ptp_delay;
        end
    end
    
    // 主逻辑计数器
    always @(posedge clk) begin
        if (rst) begin
            ns_counter <= 64'h0;
            sub_ns <= 32'h0;
            ts_valid <= 1'b0;
        end else begin
            // 优化的计数器和计时逻辑
            if (pps_d1) begin
                // PPS优先级高于计数器递增
                ns_counter <= ptp_delay_d1;
                sub_ns <= next_sub_ns - (sub_ns_overflow ? NS_PER_SEC : 0);
            end else begin
                // 正常计数器递增
                sub_ns <= next_sub_ns - (sub_ns_overflow ? NS_PER_SEC : 0);
                ns_counter <= ns_counter + (sub_ns_overflow ? 64'h1 : 64'h0);
            end
            
            // 时间戳输出逻辑优化
            if (pps_d2) begin
                tx_timestamp <= {ns_counter, sub_ns};
                ts_valid <= 1'b1;
            end else begin
                ts_valid <= 1'b0;
            end
        end
    end
endmodule