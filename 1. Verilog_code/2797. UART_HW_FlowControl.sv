module UART_HW_FlowControl #(
    parameter FLOW_THRESH = 4  // FIFO阈值
)(
    input  wire clk,
    input  wire rst_n,
    output wire rts,  // 请求发送
    input  wire cts,  // 清除发送
    // 添加FIFO接口
    input  wire [7:0] tx_fifo_space,
    input  wire [7:0] rx_fifo_used,
    input  wire tx_valid,
    output reg  tx_fifo_wr
);
// 流控状态结构
reg tx_allow;  // CTS有效标志
reg rx_ready;  // RTS有效标志

// 流控状态机
localparam FLOW_IDLE = 1'b0;
localparam FLOW_HOLD = 1'b1;

reg flow_state, next_state;
wire cts_sync;
reg tx_fifo_empty;

// 发送流控逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_allow <= 0;
        tx_fifo_wr <= 0;
        flow_state <= FLOW_IDLE;
        tx_fifo_empty <= 1;
        rx_ready <= 0; // 初始化之前未初始化的寄存器
    end else begin
        tx_allow <= (tx_fifo_space > FLOW_THRESH) && cts_sync;
        if (tx_allow && tx_valid) 
            tx_fifo_wr <= 1'b1;
        else
            tx_fifo_wr <= 1'b0;
            
        // 状态机更新
        flow_state <= next_state;
        
        // 更新tx_fifo_empty，基于tx_fifo_space
        tx_fifo_empty <= (tx_fifo_space == 8'hFF); // 假设满空间表示FIFO为空
    end
end

// 接收流控逻辑
assign rts = (rx_fifo_used <= FLOW_THRESH);

// 添加简单的sync_cell实现
reg cts_reg1, cts_reg2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cts_reg1 <= 1'b0;
        cts_reg2 <= 1'b0;
    end else begin
        cts_reg1 <= cts;
        cts_reg2 <= cts_reg1;
    end
end

assign cts_sync = cts_reg2;

// 流控状态机组合逻辑
always @(*) begin
    next_state = flow_state;
    
    case(flow_state)
        FLOW_IDLE: 
            if (!cts_sync) 
                next_state = FLOW_HOLD;
        FLOW_HOLD:
            if (tx_fifo_empty)
                next_state = FLOW_IDLE;
    endcase
end
endmodule