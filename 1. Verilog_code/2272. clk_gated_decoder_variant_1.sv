//SystemVerilog
module clk_gated_decoder(
    input clk,
    input [2:0] addr,
    input enable,
    output reg [7:0] select
);
    // 将寄存器移到组合逻辑之前
    reg [2:0] addr_reg;
    reg enable_reg;
    
    // 后向寄存器重定时 - 将输出寄存器逻辑移到数据源方向
    always @(posedge clk) begin
        addr_reg <= addr;
        enable_reg <= enable;
    end
    
    // 组合逻辑直接连接到输出
    // 解码逻辑移到寄存器之后
    always @(*) begin
        if (enable_reg)
            select = (8'b00000001 << addr_reg);
        else
            select = select; // 保持原值
    end
endmodule