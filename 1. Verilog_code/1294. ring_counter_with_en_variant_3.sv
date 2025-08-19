//SystemVerilog
module ring_counter_with_en (
    input wire clk,
    input wire rst,
    
    // Valid-Ready握手接口 (替代原先的en单信号接口)
    input wire valid,
    output reg ready,
    
    output reg [3:0] q
);
    reg [3:0] q_next;
    reg handshake_complete;
    
    // 握手逻辑：当valid和ready都为高时表示成功握手
    wire handshake = valid && ready;
    
    // Ready信号生成逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready <= 1'b1; // 复位时，模块准备好接收新数据
            handshake_complete <= 1'b0;
        end else begin
            if (valid && ready) begin
                // 成功握手后，暂时拉低ready以确保一个周期只处理一次数据
                ready <= 1'b0;
                handshake_complete <= 1'b1;
            end else if (handshake_complete) begin
                // 数据处理完成后，重新拉高ready准备下一次握手
                ready <= 1'b1;
                handshake_complete <= 1'b0;
            end else begin
                ready <= 1'b1; // 默认状态为就绪
            end
        end
    end
    
    // 计算下一状态逻辑
    always @(*) begin
        if (rst) begin
            q_next = 4'b0001; // 复位状态
        end else if (handshake) begin
            q_next = {q[0], q[3:1]}; // 环形计数操作
        end else begin
            q_next = q; // 保持当前状态
        end
    end
    
    // 状态更新逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= 4'b0001;
        end else begin
            q <= q_next;
        end
    end
endmodule