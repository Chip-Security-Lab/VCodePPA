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
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            phase_reg <= {1'b1, {(2**PHASE_BITS-1){1'b0}}};
            clk_out <= 1'b0;
        end else begin
            phase_reg <= {phase_reg[2**PHASE_BITS-2:0], phase_reg[2**PHASE_BITS-1]};
            clk_out <= phase_reg[phase_sel];
        end
    end
endmodule