//SystemVerilog
module phase_shift_clk #(
    parameter PHASE_BITS = 3
)(
    input clk_in,
    input reset,
    input [PHASE_BITS-1:0] phase_sel,
    output reg clk_out
);
    reg [2**PHASE_BITS-1:0] phase_reg;
    reg [PHASE_BITS-1:0] phase_sel_reg;
    reg phase_selected_bit;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            phase_reg <= {1'b1, {(2**PHASE_BITS-1){1'b0}}};
            phase_sel_reg <= {PHASE_BITS{1'b0}};
            phase_selected_bit <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            // 移位寄存器逻辑
            phase_reg <= {phase_reg[2**PHASE_BITS-2:0], phase_reg[2**PHASE_BITS-1]};
            
            // 流水线第一级：寄存相位选择
            phase_sel_reg <= phase_sel;
            
            // 流水线第二级：根据寄存的相位选择选取比特
            phase_selected_bit <= phase_reg[phase_sel_reg];
            
            // 流水线第三级：输出
            clk_out <= phase_selected_bit;
        end
    end
endmodule