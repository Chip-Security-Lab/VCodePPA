//SystemVerilog
module johnson_counter(
    input wire clk,           // 时钟信号
    input wire reset,         // 复位信号
    input wire ready,         // 接收方就绪信号
    output reg valid,         // 数据有效信号
    output reg [3:0] q        // 计数器输出
);
    // 优化点1: 将组合逻辑简化为单一表达式以减少延迟
    wire [3:0] next_q;
    assign next_q = {q[2:0], ~q[3]}; // 直接使用assign声明减少层次

    // 状态控制信号
    reg update_pending;
    wire handshake_complete;  // 优化点2: 提前计算条件
    wire prepare_new_data;    // 优化点3: 分解复杂条件为简单信号
    
    // 优化点4: 将条件逻辑预计算，减少时序路径中的逻辑深度
    assign handshake_complete = ready && valid;
    assign prepare_new_data = !update_pending && !valid;
    
    // 更新计数器状态及握手信号
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 4'b0000;
            valid <= 1'b0;
            update_pending <= 1'b0;
        end
        else begin
            // 优化点5: 调整条件判断顺序，优先处理高频路径
            if (handshake_complete) begin
                // 握手完成，更新计数器
                q <= next_q;
                update_pending <= 1'b0;
            end
            else if (prepare_new_data) begin
                // 准备新数据
                valid <= 1'b1;
                update_pending <= 1'b1;
            end
            else if (!ready && valid) begin
                // 接收方未就绪，保持数据和有效信号
                valid <= valid; // 优化点6: 显式保持信号以明确意图
            end
        end
    end
endmodule