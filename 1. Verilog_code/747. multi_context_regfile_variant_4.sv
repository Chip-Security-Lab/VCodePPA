//SystemVerilog
module multi_context_regfile #(
    parameter DW = 32,
    parameter AW = 3,
    parameter CTX_BITS = 3
)(
    input clk,
    input [CTX_BITS-1:0] ctx_sel,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] ctx_bank [0:7][0:(1<<AW)-1]; // 8个上下文
    
    // 寄存器缓存地址和上下文选择信号，切断组合逻辑路径
    reg [AW-1:0] addr_reg;
    reg [CTX_BITS-1:0] ctx_sel_reg;
    
    always @(posedge clk) begin
        // 写入操作
        if (wr_en) ctx_bank[ctx_sel][addr] <= din;
        
        // 缓存读取地址和上下文选择
        addr_reg <= addr;
        ctx_sel_reg <= ctx_sel;
        
        // 读取操作流水线化 - 使用缓存的地址和上下文
        dout <= ctx_bank[ctx_sel_reg][addr_reg];
    end
endmodule