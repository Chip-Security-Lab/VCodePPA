//SystemVerilog
module binary_to_thermo #(
    parameter BIN_WIDTH = 3
)(
    input  wire [BIN_WIDTH-1:0] bin_in,
    output reg  [(1<<BIN_WIDTH)-1:0] thermo_out
);

    // Internal signal for index
    integer thermo_index;

    // -------------------------------------------------------------------------
    // Always block: Clear thermo_out before setting
    // Function: Resets thermo_out to all zeros before setting ones
    // -------------------------------------------------------------------------
    always @(*) begin
        thermo_out = {((1<<BIN_WIDTH)){1'b0}};
    end

    // -------------------------------------------------------------------------
    // Always block: Set thermo_out bits according to bin_in
    // Function: Sets bits [0:bin_in-1] to 1, others remain 0
    // -------------------------------------------------------------------------
    always @(*) begin
        for (thermo_index = 0; thermo_index < (1<<BIN_WIDTH); thermo_index = thermo_index + 1) begin
            if (thermo_index < bin_in)
                thermo_out[thermo_index] = 1'b1;
        end
    end

endmodule