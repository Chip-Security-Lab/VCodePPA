//SystemVerilog
// IEEE 1364-2005 Verilog
module GatedClockShift #(parameter BITS=8) (
    input gclk,  // 门控时钟
    input en, s_in,
    output [BITS-1:0] q
);
    // 内部寄存器定义
    reg [BITS-2:0] q_internal;
    reg s_in_reg;
    
    // 合并具有相同触发条件的always块
    always @(posedge gclk) begin
        if (en) begin
            s_in_reg <= s_in;
            q_internal <= q_internal >> 1;
        end
    end
    
    // 输出组合逻辑
    assign q = {q_internal, s_in_reg};
endmodule