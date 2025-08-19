//SystemVerilog
module piso_shifter(
    input clk,
    input rst,
    input load,
    input [7:0] parallel_in,
    output serial_out
);

    reg [7:0] shift_reg_next;
    reg [7:0] shift_reg;

    // Move register after combination logic for retiming
    always @(*) begin
        case ({rst, load})
            2'b10: shift_reg_next = 8'b0;                            // Reset active
            2'b01: shift_reg_next = parallel_in;                     // Load active
            2'b00: shift_reg_next = {shift_reg[6:0], 1'b0};          // Shift operation
            default: shift_reg_next = shift_reg;                     // Hold value (covers 2'b11)
        endcase
    end

    always @(posedge clk) begin
        shift_reg <= shift_reg_next;
    end

    assign serial_out = shift_reg[7];

endmodule