//SystemVerilog
module ring_hotcode_sync (
    input clock, sync_rst,
    output reg [3:0] cnt_reg
);

// 同步复位寄存器
reg sync_rst_reg;

// 优化的组合逻辑，直接在时钟边沿更新时使用
// 无需单独的next_cnt寄存器
wire [3:0] next_cnt;
assign next_cnt = {cnt_reg[0], cnt_reg[3:1]};

// 复位同步逻辑
always @(posedge clock) begin
    sync_rst_reg <= sync_rst;
end

// 优化的状态更新逻辑
// 使用非阻塞赋值确保正确的时序行为
always @(posedge clock) begin
    if (sync_rst_reg)
        cnt_reg <= 4'b0001; // 热码初始状态
    else
        cnt_reg <= next_cnt;
end

endmodule