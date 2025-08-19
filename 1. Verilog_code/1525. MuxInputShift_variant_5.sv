//SystemVerilog
// IEEE 1364-2005 Verilog
module MuxInputShift #(parameter W=4) (
    input clk,
    input [1:0] sel,
    input [W-1:0] d0, d1, d2, d3,
    output reg [W-1:0] q
);
    reg [W-1:0] d0_reg, d1_reg, d2_reg, d3_reg;
    reg [1:0] sel_reg;
    reg [W-1:0] next_q;
    
    // 寄存器同步更新
    always @(posedge clk) begin
        d0_reg <= d0;
        d1_reg <= d1;
        d2_reg <= d2;
        d3_reg <= d3;
        sel_reg <= sel;
        q <= next_q;
    end
    
    // 组合逻辑计算next_q - 优化后的路径平衡结构
    always @(*) begin
        case (sel_reg)
            2'b00: next_q = {q[W-2:0], d0_reg[0]};
            2'b01: next_q = {q[W-2:0], d1_reg[0]};
            2'b10: next_q = {d2_reg[W-1], q[W-1:1]};
            2'b11: next_q = d3_reg;
            default: next_q = q;
        endcase
    end
endmodule