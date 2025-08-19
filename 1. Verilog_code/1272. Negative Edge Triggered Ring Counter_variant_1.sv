//SystemVerilog
module neg_edge_ring_counter #(parameter BITS = 4)(
    input wire clock,
    output reg [BITS-1:0] state
);
    // 内部缓冲寄存器，用于减少state的扇出负载
    reg [BITS-1:0] state_internal;
    
    // 初始化状态
    initial begin
        state_internal = {{(BITS-1){1'b0}}, 1'b1};
        state = {{(BITS-1){1'b0}}, 1'b1};
    end
    
    // 内部状态更新逻辑
    always @(negedge clock) begin
        state_internal <= {state_internal[BITS-2:0], state_internal[BITS-1]};
    end
    
    // 缓冲输出状态，分散负载
    always @(negedge clock) begin
        state <= state_internal;
    end
endmodule