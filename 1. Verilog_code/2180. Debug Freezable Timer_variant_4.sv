//SystemVerilog
module debug_timer #(parameter WIDTH = 16)(
    input wire clk, rst_n, enable, debug_mode,
    input wire [WIDTH-1:0] reload,
    output reg [WIDTH-1:0] count,
    output wire expired
);
    reg reload_pending;
    
    // 状态编码
    localparam [1:0] 
        NORMAL_COUNT = 2'b00,
        RELOAD_COUNT = 2'b01,
        DEBUG_EXPIRED = 2'b10,
        NO_ACTION = 2'b11;
    
    // 合并所有组合逻辑和时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            count <= {WIDTH{1'b0}};
            reload_pending <= 1'b0;
        end
        else begin
            // 默认保持当前值
            reload_pending <= reload_pending;
            
            if (enable && !debug_mode) begin
                if (count == {WIDTH{1'b1}} || reload_pending) begin
                    // RELOAD_COUNT
                    count <= reload;
                    reload_pending <= 1'b0;
                end
                else begin
                    // NORMAL_COUNT
                    count <= count + 1'b1;
                    reload_pending <= 1'b0;
                end
            end 
            else if (debug_mode && count == {WIDTH{1'b1}}) begin
                // DEBUG_EXPIRED
                count <= count;  // 保持当前计数值
                reload_pending <= 1'b1;
            end
            // 其他情况 (NO_ACTION) 保持当前值
        end
    end
    
    // 到期信号生成
    assign expired = (count == {WIDTH{1'b1}}) && enable && !debug_mode;
    
endmodule