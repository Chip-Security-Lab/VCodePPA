//SystemVerilog
module ptp_timestamp #(
    parameter CLOCK_PERIOD_NS = 4
)(
    input clk,
    input rst,
    input pps,
    input [63:0] ptp_delay,
    output reg [95:0] tx_timestamp,
    output reg ts_valid
);
    // 常量预计算
    localparam [31:0] SUB_NS_THRESHOLD = 1000 - CLOCK_PERIOD_NS;

    // Pipeline stage 1: Counter and PPS detection
    reg [63:0] ns_counter_stage1;
    reg [31:0] sub_ns_stage1;
    reg pps_detected_stage1;
    reg [63:0] ptp_delay_stage1;
    
    // Pipeline stage 2: Sub-nanosecond adjustment
    reg [63:0] ns_counter_stage2;
    reg [31:0] sub_ns_stage2;
    reg pps_detected_stage2;
    reg sub_ns_overflow_stage2;
    
    // Pipeline stage 3: Nanosecond adjustment
    reg [63:0] ns_counter_stage3;
    reg [31:0] sub_ns_stage3;
    reg pps_detected_stage3;
    
    // Pipeline stage 4: Timestamp generation
    reg [63:0] ns_counter_stage4;
    reg [31:0] sub_ns_stage4;
    reg pps_sync_stage4;
    
    // 提前计算下一个sub_ns值和是否溢出
    reg [31:0] next_sub_ns;
    reg next_sub_ns_overflow;
    
    // 预计算下一个sub_ns和溢出标志
    always @(*) begin
        next_sub_ns = sub_ns_stage1 + CLOCK_PERIOD_NS;
        next_sub_ns_overflow = (sub_ns_stage1 > SUB_NS_THRESHOLD);
    end
    
    // Stage 1: Counter and PPS detection
    always @(posedge clk) begin
        if (rst) begin
            ns_counter_stage1 <= 64'h0;
            sub_ns_stage1 <= 32'h0;
            pps_detected_stage1 <= 1'b0;
            ptp_delay_stage1 <= 64'h0;
        end else begin
            // 使用stage3的值而不是通过多级传递
            ns_counter_stage1 <= ns_counter_stage3;
            sub_ns_stage1 <= sub_ns_stage3;
            pps_detected_stage1 <= pps;
            ptp_delay_stage1 <= ptp_delay;
        end
    end
    
    // Stage 2: Sub-nanosecond adjustment calculation
    always @(posedge clk) begin
        if (rst) begin
            ns_counter_stage2 <= 64'h0;
            sub_ns_stage2 <= 32'h0;
            pps_detected_stage2 <= 1'b0;
            sub_ns_overflow_stage2 <= 1'b0;
        end else begin
            // 直接传递PPS检测信号
            pps_detected_stage2 <= pps_detected_stage1;
            
            // 使用预计算的sub_ns和溢出标志
            sub_ns_stage2 <= next_sub_ns;
            sub_ns_overflow_stage2 <= next_sub_ns_overflow;
            
            // 直接传递计数器值
            ns_counter_stage2 <= ns_counter_stage1;
        end
    end
    
    // Stage 3: Nanosecond adjustment
    always @(posedge clk) begin
        if (rst) begin
            ns_counter_stage3 <= 64'h0;
            sub_ns_stage3 <= 32'h0;
            pps_detected_stage3 <= 1'b0;
        end else begin
            if (pps_detected_stage2) begin
                // PPS事件发生时重置计数器
                ns_counter_stage3 <= ptp_delay_stage1;
                sub_ns_stage3 <= 32'h0;
            end else if (sub_ns_overflow_stage2) begin
                // 当sub_ns溢出时增加ns计数器
                ns_counter_stage3 <= ns_counter_stage2 + 64'h1;
                sub_ns_stage3 <= next_sub_ns - 1000; // 预先计算溢出后的值
            end else begin
                // 正常计数情况
                ns_counter_stage3 <= ns_counter_stage2;
                sub_ns_stage3 <= sub_ns_stage2;
            end
            
            // 直接传递PPS检测信号
            pps_detected_stage3 <= pps_detected_stage2;
        end
    end
    
    // Stage 4: Timestamp generation
    always @(posedge clk) begin
        if (rst) begin
            ns_counter_stage4 <= 64'h0;
            sub_ns_stage4 <= 32'h0;
            pps_sync_stage4 <= 1'b0;
            tx_timestamp <= 96'h0;
            ts_valid <= 1'b0;
        end else begin
            // 直接传递时间戳值
            ns_counter_stage4 <= ns_counter_stage3;
            sub_ns_stage4 <= sub_ns_stage3;
            
            // 简化PPS同步逻辑
            if (pps_detected_stage3) begin
                // PPS检测到时设置同步标志
                pps_sync_stage4 <= 1'b1;
                ts_valid <= 1'b0;
            end else if (pps_sync_stage4) begin
                // 同步标志置位时生成时间戳
                tx_timestamp <= {ns_counter_stage4, sub_ns_stage4};
                ts_valid <= 1'b1;
                pps_sync_stage4 <= 1'b0;
            end else begin
                // 其他情况
                ts_valid <= 1'b0;
            end
        end
    end
endmodule