//SystemVerilog
module int_ctrl_dyn_prio #(parameter N=4)(
    input clk,
    input [N-1:0] int_req,
    input [N-1:0] prio_reg,
    output reg [N-1:0] grant
);
    // 使用更高效的并行赋值替代while循环
    // 通过位级与操作实现优先级控制
    always @(*) begin
        grant = int_req & prio_reg;
    end
endmodule