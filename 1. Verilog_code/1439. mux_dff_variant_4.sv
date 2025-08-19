//SystemVerilog
module mux_dff (
    input clk, sel,
    input d0, d1,
    output reg q
);
    reg sel_reg;
    reg d0_reg, d1_reg;
    
    always @(posedge clk) begin
        // 将输入信号寄存
        sel_reg <= sel;
        d0_reg <= d0;
        d1_reg <= d1;
        
        // 使用寄存后的信号进行多路选择
        q <= sel_reg ? d1_reg : d0_reg;
    end
endmodule