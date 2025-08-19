//SystemVerilog
module controlled_ring_counter(
    input wire clock,
    input wire reset,
    input wire valid,     // 发送方表示数据有效 (原run信号)
    output wire ready,    // 接收方表示准备好接收
    output reg [3:0] state
);
    // 内部状态控制
    reg ready_r;
    reg state_valid;      // 表示state输出有效
    reg [3:0] next_state;
    
    // Ready信号生成 - 当系统未处于复位状态时可以接收
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ready_r <= 1'b1;     // 复位后即可接收新数据
            state_valid <= 1'b0;
        end
        else begin
            if (valid && ready_r) begin
                // 握手成功，状态将更新
                state_valid <= 1'b1;
                ready_r <= 1'b0;     // 暂时不接收新请求
            end
            else if (state_valid) begin
                // 状态已更新，可以接收新请求
                ready_r <= 1'b1;
                state_valid <= 1'b0;
            end
        end
    end
    
    // 状态更新逻辑
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= 4'b0001;
        end
        else if (valid && ready_r) begin
            // 握手成功时更新状态
            state <= {state[2:0], state[3]};
        end
    end
    
    // 将内部ready寄存器连接到输出
    assign ready = ready_r;
    
endmodule