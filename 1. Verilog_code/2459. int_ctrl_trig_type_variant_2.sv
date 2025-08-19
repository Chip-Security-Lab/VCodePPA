//SystemVerilog
module int_ctrl_trig_type #(parameter WIDTH=4)(
    input  wire             clk,
    input  wire [WIDTH-1:0] int_src,
    input  wire [WIDTH-1:0] trig_type,  // 0=level 1=edge
    output wire [WIDTH-1:0] int_out
);
    reg [WIDTH-1:0] sync_reg, prev_reg;
    
    always @(posedge clk) begin
        prev_reg <= sync_reg;
        sync_reg <= int_src;
    end
    
    // 优化的检测和选择逻辑
    // 合并边沿和电平检测到一个表达式中
    // 使用位级运算优化多路复用器结构
    assign int_out = (sync_reg & ((~prev_reg & trig_type) | ~trig_type));
    
endmodule