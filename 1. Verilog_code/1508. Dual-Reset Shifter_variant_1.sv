//SystemVerilog
// IEEE 1364-2005 Verilog标准
module dual_reset_shifter #(parameter WIDTH = 8) (
    input wire clk, sync_rst, async_rst, enable, data_in,
    output reg [WIDTH-1:0] data_out
);
    // 定义中间变量，用于清晰表达条件逻辑
    reg do_sync_reset;
    reg do_shift;
    
    // 组合逻辑：简化条件表达式为多个简单条件判断
    always @(*) begin
        // 默认状态：无操作
        do_sync_reset = 1'b0;
        do_shift = 1'b0;
        
        // 按优先级逐级判断
        if (~async_rst) begin  // 只有在没有异步复位时考虑其他条件
            if (sync_rst) begin
                do_sync_reset = 1'b1;  // 同步复位条件
            end else if (enable) begin
                do_shift = 1'b1;       // 移位使能条件
            end
        end
    end
    
    // 时序逻辑：处理异步复位和时钟触发的操作
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            // 异步复位具有最高优先级
            data_out <= {WIDTH{1'b0}};
        end else begin
            if (do_sync_reset) begin
                // 同步复位操作
                data_out <= {WIDTH{1'b0}};
            end else if (do_shift) begin
                // 移位操作
                data_out <= {data_out[WIDTH-2:0], data_in};
            end
            // 如果没有任何条件满足，保持当前值（隐含）
        end
    end
endmodule