//SystemVerilog
module ResetDelayDetector #(
    parameter DELAY = 4
) (
    input wire clk,
    input wire rst_n,
    output wire reset_detected
);
    reg [DELAY-1:0] reset_shift_reg;
    wire all_zeros;

    assign all_zeros = (reset_shift_reg == {DELAY{1'b0}});
    assign reset_detected = ~all_zeros;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_shift_reg <= {DELAY{1'b1}};
        else if (!all_zeros)
            reset_shift_reg <= {reset_shift_reg[DELAY-2:0], 1'b0};
    end
endmodule