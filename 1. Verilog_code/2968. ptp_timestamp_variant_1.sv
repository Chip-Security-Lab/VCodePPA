//SystemVerilog
//-----------------------------------------------------------------------------
// File: ptp_timestamp_system.v
//
// 顶层模块：PTP时间戳系统
//-----------------------------------------------------------------------------
module ptp_timestamp_system #(
    parameter CLOCK_PERIOD_NS = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        pps,
    input  wire [63:0] ptp_delay,
    output wire [95:0] tx_timestamp,
    output wire        ts_valid
);

    // 内部连接信号
    wire [63:0] ns_counter;
    wire [31:0] sub_ns;
    wire        pps_sync;

    // 纳秒和亚纳秒计数器子模块
    timestamp_counter #(
        .CLOCK_PERIOD_NS(CLOCK_PERIOD_NS)
    ) counter_inst (
        .clk        (clk),
        .rst        (rst),
        .pps        (pps),
        .ptp_delay  (ptp_delay),
        .ns_counter (ns_counter),
        .sub_ns     (sub_ns),
        .pps_sync   (pps_sync)
    );

    // 时间戳输出控制子模块
    timestamp_output output_inst (
        .clk         (clk),
        .rst         (rst),
        .ns_counter  (ns_counter),
        .sub_ns      (sub_ns),
        .pps_sync    (pps_sync),
        .tx_timestamp(tx_timestamp),
        .ts_valid    (ts_valid)
    );

endmodule

//-----------------------------------------------------------------------------
// 子模块：时间戳计数器
// 功能：维护纳秒和亚纳秒计数器，处理PPS同步信号
//-----------------------------------------------------------------------------
module timestamp_counter #(
    parameter CLOCK_PERIOD_NS = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        pps,
    input  wire [63:0] ptp_delay,
    output reg  [63:0] ns_counter,
    output reg  [31:0] sub_ns,
    output reg         pps_sync
);

    // 纳秒和亚纳秒计数逻辑
    always @(posedge clk) begin
        if (rst) begin
            ns_counter <= 64'h0;
            sub_ns     <= 32'h0;
            pps_sync   <= 1'b0;
        end else begin
            // 更新亚纳秒计数器
            sub_ns <= sub_ns + CLOCK_PERIOD_NS;
            
            // 纳秒进位逻辑
            if (sub_ns >= 1000) begin
                ns_counter <= ns_counter + 1'b1;
                sub_ns     <= sub_ns - 1000;
            end
            
            // PPS同步处理
            if (pps) begin
                ns_counter <= ptp_delay;
                pps_sync   <= 1'b1;
            end else if (pps_sync) begin
                pps_sync   <= 1'b0;
            end
        end
    end

endmodule

//-----------------------------------------------------------------------------
// 子模块：时间戳输出控制
// 功能：根据PPS同步信号生成有效时间戳输出
//-----------------------------------------------------------------------------
module timestamp_output (
    input  wire        clk,
    input  wire        rst,
    input  wire [63:0] ns_counter,
    input  wire [31:0] sub_ns,
    input  wire        pps_sync,
    output reg  [95:0] tx_timestamp,
    output reg         ts_valid
);

    // 时间戳输出控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            tx_timestamp <= 96'h0;
            ts_valid     <= 1'b0;
        end else begin
            if (pps_sync) begin
                // 生成时间戳输出：纳秒计数器(64位) + 亚纳秒计数器(32位)
                tx_timestamp <= {ns_counter, sub_ns};
                ts_valid     <= 1'b1;
            end else begin
                ts_valid     <= 1'b0;
            end
        end
    end

endmodule