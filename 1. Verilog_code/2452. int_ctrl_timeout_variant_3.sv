//SystemVerilog
module int_ctrl_timeout #(
    parameter TIMEOUT = 8
)(
    input wire clk,
    input wire int_pending,
    output reg timeout
);
    // 使用最小位宽，减少资源使用
    reg [$clog2(TIMEOUT+1)-1:0] counter;
    wire timeout_condition;
    
    // 为高扇出信号添加缓冲寄存器
    reg timeout_condition_buf1;
    reg timeout_condition_buf2;
    
    // 优化比较逻辑
    assign timeout_condition = (counter >= TIMEOUT);
    
    always @(posedge clk) begin
        // 缓冲寄存器1 - 用于计数器逻辑
        timeout_condition_buf1 <= timeout_condition;
        
        // 缓冲寄存器2 - 用于timeout输出
        timeout_condition_buf2 <= timeout_condition;
        
        if (int_pending) begin
            counter <= timeout_condition_buf1 ? '0 : counter + 1'b1;
        end
        
        timeout <= timeout_condition_buf2;
    end
endmodule