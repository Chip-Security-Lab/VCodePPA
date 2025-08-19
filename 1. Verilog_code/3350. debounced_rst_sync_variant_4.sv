//SystemVerilog
module debounced_rst_sync #(
    parameter DEBOUNCE_LEN = 8
)(
    input  wire clk,
    input  wire noisy_rst_n,
    output reg  clean_rst_n
);
    reg [1:0] sync_flops;
    reg [3:0] debounce_counter;
    wire reset_active;
    wire counter_max;
    
    // 使用信号断言来提高可读性和效率
    assign reset_active = ~sync_flops[1];
    assign counter_max = (debounce_counter == DEBOUNCE_LEN-1);
    
    always @(posedge clk) begin
        // 同步器逻辑保持不变但分离
        sync_flops <= {sync_flops[0], noisy_rst_n};
        
        // 优化比较链和计数器逻辑
        if (reset_active) begin
            // 只有当计数器未达到最大值时才增加
            debounce_counter <= counter_max ? debounce_counter : debounce_counter + 1'b1;
            // 当且仅当计数器达到最大值时设置clean_rst_n为0
            clean_rst_n <= ~counter_max ? clean_rst_n : 1'b0;
        end else begin
            debounce_counter <= 4'b0;
            clean_rst_n <= 1'b1;
        end
    end
endmodule