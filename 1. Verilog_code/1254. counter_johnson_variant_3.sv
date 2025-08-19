//SystemVerilog
//IEEE 1364-2005 Verilog
module counter_johnson #(parameter STAGES=8) (
    input wire clk, rst,
    output reg [STAGES-1:0] j_reg
);
    // 查找表用于减法器实现
    reg [STAGES-1:0] next_state_lut [0:2**STAGES-1];
    reg [STAGES-1:0] next_state;
    
    // 初始化查找表
    integer i;
    initial begin
        for (i = 0; i < 2**STAGES; i = i + 1) begin
            next_state_lut[i] = {~i[0], i[STAGES-1:1]};
        end
    end
    
    // 查找下一状态
    always @(*) begin
        if (rst)
            next_state = {STAGES{1'b0}};
        else
            next_state = next_state_lut[j_reg];
    end
    
    // 时序逻辑
    always @(posedge clk) begin
        j_reg <= next_state;
    end

endmodule