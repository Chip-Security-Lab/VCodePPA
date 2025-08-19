module siso_shifter(
    input wire clock, clear,
    input wire serial_data_in,
    output wire serial_data_out
);
    reg [3:0] shift_reg;
    always @(posedge clock) begin
        if (clear)
            shift_reg <= 4'b0000;
        else
            shift_reg <= {shift_reg[2:0], serial_data_in};
    end
    assign serial_data_out = shift_reg[3];
endmodule