//SystemVerilog
module quad_phase_gen #(
    parameter PHASE_NUM = 4
)(
    input clk,
    input rst_n,
    output reg [PHASE_NUM-1:0] phase_clks
);

always @(posedge clk or negedge rst_n) begin
    phase_clks <= (!rst_n) ? 4'b0001 : {phase_clks[PHASE_NUM-2:0], phase_clks[PHASE_NUM-1]};
end

endmodule