//SystemVerilog
module ResetDelayDetector #(
    parameter DELAY = 4
) (
    input wire clk,
    input wire rst_n,
    output wire reset_detected
);
    localparam SHIFT_WIDTH = DELAY;

    reg [SHIFT_WIDTH-1:0] reset_shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_shift_reg <= {SHIFT_WIDTH{1'b1}};
        end else begin
            reset_shift_reg <= {reset_shift_reg[SHIFT_WIDTH-2:0], 1'b0};
        end
    end

    assign reset_detected = reset_shift_reg[SHIFT_WIDTH-1];

endmodule