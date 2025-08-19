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
    // 寄存器定义
    reg [63:0] ns_counter;
    reg [31:0] sub_ns;
    reg pps_sync, pps_sync_next;
    reg sub_ns_overflow;
    
    // 预计算常量，减少运行时计算
    localparam SUB_NS_MAX = 1000 - CLOCK_PERIOD_NS;
    
    // 子纳秒预计算逻辑 - 优化关键路径
    wire sub_ns_will_overflow = (sub_ns > SUB_NS_MAX);
    wire [31:0] sub_ns_next = sub_ns_will_overflow ? 
                              (sub_ns + CLOCK_PERIOD_NS - 1000) : 
                              (sub_ns + CLOCK_PERIOD_NS);
    
    // 纳秒计数器更新逻辑
    wire [63:0] ns_counter_next = pps ? ptp_delay :
                                  sub_ns_overflow ? (ns_counter + 1) : 
                                  ns_counter;
    
    // PPS同步逻辑优化
    always @(*) begin
        case ({pps, pps_sync})
            2'b10: pps_sync_next = 1'b1;
            2'b11: pps_sync_next = 1'b0;
            default: pps_sync_next = pps_sync;
        endcase
    end
    
    // 寄存器更新 - 分离组合逻辑和时序逻辑
    always @(posedge clk) begin
        if (rst) begin
            sub_ns <= 0;
            sub_ns_overflow <= 0;
            ns_counter <= 0;
            pps_sync <= 0;
            ts_valid <= 0;
            tx_timestamp <= 0;
        end else begin
            // 更新子纳秒计数器和溢出标志
            sub_ns <= sub_ns_next;
            sub_ns_overflow <= sub_ns_will_overflow;
            
            // 更新纳秒计数器
            ns_counter <= ns_counter_next;
            
            // 更新PPS同步状态
            pps_sync <= pps_sync_next;
            
            // 更新时间戳输出
            ts_valid <= pps_sync;
            if (pps_sync) begin
                tx_timestamp <= {ns_counter, sub_ns};
            end
        end
    end
endmodule