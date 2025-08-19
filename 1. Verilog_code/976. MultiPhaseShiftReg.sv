module MultiPhaseShiftReg #(parameter PHASES=4, WIDTH=8) (
    input [PHASES-1:0] phase_clk,
    input serial_in,
    output [PHASES-1:0] phase_out
);
genvar i;
generate
    for(i=0; i<PHASES; i=i+1) begin
        reg [WIDTH-1:0] shift_reg;
        always @(posedge phase_clk[i]) begin
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
        end
        assign phase_out[i] = shift_reg[WIDTH-1];
    end
endgenerate
endmodule