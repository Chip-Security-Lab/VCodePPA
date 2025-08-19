//SystemVerilog
module ring_counter_with_en (
    input  wire       clk,     // 时钟信号
    input  wire       rst,     // 复位信号
    input  wire       valid,   // 数据有效信号
    output wire       ready,   // 准备接收信号
    output reg  [3:0] q        // 计数器输出
);

    // ===== 流水线阶段定义 =====
    // 阶段1: 握手控制信号处理
    reg        ready_reg;      // 握手控制寄存器
    reg        handshake_done; // 握手完成标志
    
    // 阶段2: 数据路径处理
    reg  [3:0] q_next;         // 下一状态寄存器
    
    // ===== 握手控制信号逻辑 =====
    assign ready = ready_reg;
    
    // 握手控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            ready_reg <= 1'b1;       // 复位后即准备好接收数据
            handshake_done <= 1'b0;  // 复位握手完成标志
        end else begin
            handshake_done <= valid && ready_reg;  // 记录握手完成状态
            
            // 握手完成后立即准备接收下一个请求
            if (valid && ready_reg) begin
                ready_reg <= 1'b1;
            end
        end
    end
    
    // ===== 数据路径逻辑 =====
    // 计算下一状态逻辑
    always @(*) begin
        q_next = q;  // 默认保持当前状态
        
        if (handshake_done) begin
            q_next = {q[0], q[3:1]};  // 环形移位操作
        end
    end
    
    // 更新计数器状态
    always @(posedge clk) begin
        if (rst) begin
            q <= 4'b0001;  // 复位值
        end else begin
            q <= q_next;   // 更新为下一状态
        end
    end

endmodule