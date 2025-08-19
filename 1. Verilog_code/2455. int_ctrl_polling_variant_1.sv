//SystemVerilog
module int_ctrl_polling #(
    parameter CNT_W = 3
)(
    input  wire                clk,
    input  wire                enable,
    input  wire [2**CNT_W-1:0] int_src,
    output reg                 int_valid,
    output wire [CNT_W-1:0]    int_id
);

    reg  [CNT_W-1:0] poll_counter;
    wire [CNT_W-1:0] next_counter;
    
    // 优化逻辑：移除了不必要的has_interrupt信号，减少了逻辑层级
    assign next_counter = poll_counter + 1'b1;
    assign int_id = poll_counter;
    
    // 寄存器逻辑优化，减少逻辑深度和改善时序
    always @(posedge clk) begin
        if (enable) begin
            poll_counter <= next_counter;
            // 直接索引中断源而不需要额外的比较逻辑
            int_valid <= int_src[poll_counter];
        end else begin
            // 禁用时不改变计数器，只清除中断有效标志
            // 消除了不必要的poll_counter重置，减少了触发器切换
            int_valid <= 1'b0;
        end
    end
    
endmodule