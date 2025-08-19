//SystemVerilog
module TTBridge #(
    parameter SCHEDULE = 32'h0000_FFFF
)(
    input clk, rst_n,
    input [31:0] timestamp,
    output reg trigger
);
    reg [31:0] last_ts;
    wire is_scheduled;
    wire trigger_condition;
    
    // 使用位操作优化scheduling检查
    assign is_scheduled = |(timestamp & SCHEDULE);
    
    // 使用单个比较优化时间差检测
    // 避免额外的减法操作
    assign trigger_condition = is_scheduled && (timestamp >= (last_ts + 100));
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger <= 1'b0;
            last_ts <= 32'h0;
        end else begin
            // 简化逻辑并减少寄存器数量
            trigger <= trigger_condition;
            
            // 只在必要时更新last_ts
            if (trigger_condition) begin
                last_ts <= timestamp;
            end
        end
    end
endmodule