//SystemVerilog
// Top-level module: SISO Shift Register (Retimed)
module siso_shifter(
    input  wire clock,
    input  wire clear,
    input  wire serial_data_in,
    output wire serial_data_out
);

    // Internal signal for shift register output
    wire [3:0] shift_reg_data_int;
    wire       msb_reg_data;

    // Shift register logic submodule instantiation (retimed)
    shift_register_logic_retimed #(
        .WIDTH(4)
    ) u_shift_register_logic (
        .clk(clock),
        .rst(clear),
        .data_in(serial_data_in),
        .shift_out(shift_reg_data_int)
    );

    // MSB register moved from output logic to here (retimed)
    msb_register u_msb_register (
        .clk(clock),
        .rst(clear),
        .msb_in(shift_reg_data_int[3]),
        .msb_out(msb_reg_data)
    );

    // Serial output logic submodule instantiation (now pure combinational)
    serial_output_logic_retimed u_serial_output_logic (
        .msb_in(msb_reg_data),
        .serial_out(serial_data_out)
    );

endmodule

// --------------------------------------------------------------------
// Shift Register Logic Submodule (Retimed)
// Performs serial-in, serial-out shift operation with synchronous clear
// --------------------------------------------------------------------
module shift_register_logic_retimed #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             data_in,
    output reg  [WIDTH-1:0] shift_out
);
    always @(posedge clk) begin
        if (rst)
            shift_out <= {WIDTH{1'b0}};
        else
            shift_out <= {shift_out[WIDTH-2:0], data_in};
    end
endmodule

// --------------------------------------------------------------------
// MSB Register (Retimed)
// Register for the MSB, previously inside output logic, now moved after shift register
// --------------------------------------------------------------------
module msb_register(
    input  wire clk,
    input  wire rst,
    input  wire msb_in,
    output reg  msb_out
);
    always @(posedge clk) begin
        if (rst)
            msb_out <= 1'b0;
        else
            msb_out <= msb_in;
    end
endmodule

// --------------------------------------------------------------------
// Serial Output Logic Submodule (Retimed)
// Output is directly assigned from registered MSB
// --------------------------------------------------------------------
module serial_output_logic_retimed(
    input  wire msb_in,
    output wire serial_out
);
    assign serial_out = msb_in;
endmodule