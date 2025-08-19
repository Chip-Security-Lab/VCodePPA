//SystemVerilog
module UART_HW_FlowControl #(
    parameter FLOW_THRESH = 4  // FIFO阈值
)(
    input  wire clk,
    input  wire rst_n,
    output wire rts,  // 请求发送
    input  wire cts,  // 清除发送
    input  wire [7:0] tx_fifo_space,
    input  wire [7:0] rx_fifo_used,
    input  wire tx_valid,
    output reg  tx_fifo_wr
);

//-----------------------------------------------------------------------------
// 信号定义
//-----------------------------------------------------------------------------
reg tx_allow;             // 允许发送标志
reg rx_ready;             // 接收端准备好
reg flow_state;           // 当前流控状态
reg next_state;           // 下一个流控状态
wire cts_sync;            // 同步后的cts信号
reg tx_fifo_empty;        // 发送FIFO是否为空
reg cts_reg1, cts_reg2;   // CTS同步寄存器
wire tx_fifo_space_gt_thresh; // Wallace树乘法器结果输出

//-----------------------------------------------------------------------------
// Wallace树乘法器实现（8位比较器专用）
//-----------------------------------------------------------------------------
wire [7:0] diff;
wire diff_sign;

WallaceTreeSubtractor8 u_wallace_subtractor (
    .a(tx_fifo_space),
    .b(FLOW_THRESH[7:0]),
    .diff(diff),
    .sign(diff_sign)
);

assign tx_fifo_space_gt_thresh = diff_sign;

//-----------------------------------------------------------------------------
// 发送流控允许逻辑
//-----------------------------------------------------------------------------
/*
    功能: 计算是否允许发送(tx_allow)，取决于FIFO空间和CTS信号
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_allow <= 1'b0;
    end else begin
        tx_allow <= (tx_fifo_space_gt_thresh) && cts_sync;
    end
end

//-----------------------------------------------------------------------------
// 发送FIFO写入控制
//-----------------------------------------------------------------------------
/*
    功能: 控制tx_fifo_wr信号，只在允许发送且tx_valid时置位
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_fifo_wr <= 1'b0;
    end else begin
        if (tx_allow && tx_valid)
            tx_fifo_wr <= 1'b1;
        else
            tx_fifo_wr <= 1'b0;
    end
end

//-----------------------------------------------------------------------------
// FIFO空标志更新
//-----------------------------------------------------------------------------
/*
    功能: 根据tx_fifo_space更新tx_fifo_empty标志
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_fifo_empty <= 1'b1;
    end else begin
        tx_fifo_empty <= (tx_fifo_space == 8'hFF); // 假设满空间表示FIFO为空
    end
end

//-----------------------------------------------------------------------------
// 流控状态机寄存器
//-----------------------------------------------------------------------------
/*
    功能: 状态机状态寄存器flow_state更新
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flow_state <= 1'b0;
    end else begin
        flow_state <= next_state;
    end
end

//-----------------------------------------------------------------------------
// 流控状态机组合逻辑
//-----------------------------------------------------------------------------
/*
    功能: 状态机组合逻辑，产生next_state
*/
always @(*) begin
    next_state = flow_state;
    case(flow_state)
        1'b0: begin // FLOW_IDLE
            if (!cts_sync)
                next_state = 1'b1; // FLOW_HOLD
        end
        1'b1: begin // FLOW_HOLD
            if (tx_fifo_empty)
                next_state = 1'b0; // FLOW_IDLE
        end
    endcase
end

//-----------------------------------------------------------------------------
// CTS信号同步逻辑
//-----------------------------------------------------------------------------
/*
    功能: 双触发器同步CTS输入信号，消除亚稳态
*/
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

//-----------------------------------------------------------------------------
// RTS输出逻辑
//-----------------------------------------------------------------------------
/*
    功能: RTS输出，仅当接收FIFO未满时有效
*/
assign rts = (rx_fifo_used <= FLOW_THRESH);

endmodule

//-----------------------------------------------------------------------------
// Wallace树8位减法器（用于比较）
//-----------------------------------------------------------------------------
module WallaceTreeSubtractor8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] diff,
    output wire       sign // a > b为1, 否则为0
);
    wire [7:0] b_inv;
    wire       carry_in;
    wire [7:0] p0, g0;
    wire [7:0] carry;

    assign b_inv = ~b;
    assign carry_in = 1'b1; // 补码加法

    // Wallace Tree Reduction for 8-bit addition (a + (~b) + 1)
    // 1st stage: Half-Adders for each bit
    assign p0 = a ^ b_inv;
    assign g0 = a & b_inv;

    // Carry chain
    assign carry[0] = carry_in;
    assign carry[1] = g0[0] | (p0[0] & carry[0]);
    assign carry[2] = g0[1] | (p0[1] & carry[1]);
    assign carry[3] = g0[2] | (p0[2] & carry[2]);
    assign carry[4] = g0[3] | (p0[3] & carry[3]);
    assign carry[5] = g0[4] | (p0[4] & carry[4]);
    assign carry[6] = g0[5] | (p0[5] & carry[5]);
    assign carry[7] = g0[6] | (p0[6] & carry[6]);

    assign diff[0] = p0[0] ^ carry[0];
    assign diff[1] = p0[1] ^ carry[1];
    assign diff[2] = p0[2] ^ carry[2];
    assign diff[3] = p0[3] ^ carry[3];
    assign diff[4] = p0[4] ^ carry[4];
    assign diff[5] = p0[5] ^ carry[5];
    assign diff[6] = p0[6] ^ carry[6];
    assign diff[7] = p0[7] ^ carry[7];

    assign sign = ~diff[7]; // a > b时diff最高位为0

endmodule