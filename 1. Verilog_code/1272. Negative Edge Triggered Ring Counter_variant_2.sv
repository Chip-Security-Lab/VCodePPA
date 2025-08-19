//SystemVerilog
module neg_edge_ring_counter #(parameter BITS = 4)(
    input wire clock,
    output reg [BITS-1:0] state
);
    // Internal register for shifted state
    reg [BITS-1:0] internal_state;
    
    // 初始状态设置
    initial begin
        internal_state = {{(BITS-1){1'b0}}, 1'b1}; // 使用参数化初始值
        state = {{(BITS-1){1'b0}}, 1'b1};
    end
    
    // 负边沿触发时更新内部状态
    always @(negedge clock) begin
        internal_state <= {internal_state[BITS-2:0], internal_state[BITS-1]};
    end
    
    // 组合逻辑移到寄存器前面
    always @(negedge clock) begin
        state <= internal_state;
    end
endmodule