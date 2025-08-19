//SystemVerilog
module neg_edge_ring_counter #(
    parameter BITS = 4
)(
    input  wire       clock,
    input  wire       reset_n,    // 添加复位信号提高可靠性
    output reg  [BITS-1:0] state
);

    // 定义内部信号，使数据流更清晰
    reg [BITS-1:0] next_state;
    
    // 初始化逻辑（带异步复位）
    initial state = {1'b1, {(BITS-1){1'b0}}};
    
    // 计算下一状态 - 组合逻辑路径
    always @(*) begin
        next_state = {state[BITS-2:0], state[BITS-1]};
    end
    
    // 状态更新 - 时序逻辑路径
    always @(negedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state <= {1'b1, {(BITS-1){1'b0}}};  // 复位到初始状态
        end else begin
            state <= next_state;
        end
    end

endmodule