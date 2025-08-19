//SystemVerilog
// Top-level module
module MultiPhaseShiftReg #(
    parameter PHASES = 4,
    parameter WIDTH = 8
)(
    input [PHASES-1:0] phase_clk,
    input serial_in,
    output [PHASES-1:0] phase_out
);
    // Instantiate single-phase shift register for each phase
    genvar i;
    generate
        for (i = 0; i < PHASES; i = i + 1) begin : phase_instances
            SinglePhaseShiftReg #(
                .WIDTH(WIDTH)
            ) phase_shift_reg (
                .clk(phase_clk[i]),
                .serial_in(serial_in),
                .serial_out(phase_out[i])
            );
        end
    endgenerate
endmodule

// Single-phase shift register module
module SinglePhaseShiftReg #(
    parameter WIDTH = 8
)(
    input clk,
    input serial_in,
    output serial_out
);
    reg [WIDTH-1:0] shift_reg;
    
    always @(posedge clk) begin
        shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
    end
    
    assign serial_out = shift_reg[WIDTH-1];
endmodule