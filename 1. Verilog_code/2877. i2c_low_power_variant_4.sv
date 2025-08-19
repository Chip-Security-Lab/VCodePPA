//SystemVerilog
module i2c_low_power #(
    parameter AUTO_CLKGATE = 1  // Automatic clock gating
)(
    input clk_main,
    input rst_n,
    input enable,
    inout sda,
    inout scl,
    output reg clk_gated
);
// Unique feature: Dynamic clock gating
reg clk_enable_reg;
wire gated_clk;

// State definition
localparam IDLE = 2'b00;
localparam ACTIVE = 2'b01;
localparam TRANSFER = 2'b10;
reg [1:0] state, next_state;

// FIFO count
reg [3:0] fifo_count, next_fifo_count;
// 预计算的条件信号，减少关键路径延迟
wire fifo_not_empty;
wire fifo_not_full;
wire state_not_idle;

// 提前计算常用条件，减少关键路径延迟
assign fifo_not_empty = |fifo_count;
assign fifo_not_full = (fifo_count < 4'hF);
assign state_not_idle = (state != IDLE);

// Clock gating logic - 优化关键路径
assign gated_clk = clk_main & clk_enable_reg;

// Clock gating control
always @(posedge clk_main or negedge rst_n) begin
    if (!rst_n) begin
        clk_enable_reg <= 1'b0;
        clk_gated <= 1'b0;
    end else begin
        // 使用预计算的条件信号减少关键路径延迟
        clk_enable_reg <= state_not_idle || fifo_not_empty;
        clk_gated <= gated_clk;
    end
end

// State register update
always @(posedge clk_main or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// 优化的状态转换逻辑 - 简化条件判断
always @(*) begin
    // 默认保持当前状态
    next_state = state;
    
    // 分解条件逻辑，简化路径
    case (state)
        IDLE:    next_state = enable ? ACTIVE : IDLE;
        ACTIVE:  next_state = enable ? ACTIVE : IDLE;
        default: next_state = IDLE;
    endcase
end

// FIFO count register update
always @(posedge clk_main or negedge rst_n) begin
    if (!rst_n) begin
        fifo_count <= 4'h0;
    end else begin
        fifo_count <= next_fifo_count;
    end
end

// 优化的FIFO计数逻辑 - 平衡路径
always @(*) begin
    // 默认保持当前计数
    next_fifo_count = fifo_count;
    
    // 拆分复杂条件为多个简单条件，平衡路径
    if (enable && fifo_not_full) begin
        next_fifo_count = fifo_count + 4'h1;
    end else if (!enable && fifo_not_empty) begin
        next_fifo_count = fifo_count - 4'h1;
    end
end

// Using clock gating unit (synthesis directive)
// synopsys translate_off
initial $display("Using clock gating technique");
// synopsys translate_on
endmodule