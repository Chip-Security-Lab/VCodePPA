//SystemVerilog
// Top-level module: Hierarchical demux with default output
module demux_with_default (
    input  wire        data_in,       // Input data
    input  wire [2:0]  sel_addr,      // Selection address
    output wire [6:0]  outputs,       // Normal outputs
    output wire        default_out    // Default output for invalid addresses
);

    wire [6:0] demux_outputs;
    wire       def_out;

    // Instantiate the demux core submodule
    demux_core u_demux_core (
        .data_in       (data_in),
        .sel_addr      (sel_addr),
        .outputs       (demux_outputs),
        .default_valid (def_out)
    );

    // Instantiate the default output logic submodule
    default_output_logic u_default_output_logic (
        .data_in       (data_in),
        .default_valid (def_out),
        .default_out   (default_out)
    );

    assign outputs = demux_outputs;

endmodule

// -----------------------------------------------------------------------------
// Submodule: demux_core
// Function:  Performs 1-to-7 demultiplexing based on sel_addr. Indicates
//            if the address is invalid for default output handling.
// -----------------------------------------------------------------------------
module demux_core (
    input  wire        data_in,
    input  wire [2:0]  sel_addr,
    output reg  [6:0]  outputs,
    output reg         default_valid
);
    always @(*) begin
        outputs = 7'b0;
        default_valid = 1'b0;
        case (sel_addr)
            3'b000: outputs[0] = data_in;
            3'b001: outputs[1] = data_in;
            3'b010: outputs[2] = data_in;
            3'b011: outputs[3] = data_in;
            3'b100: outputs[4] = data_in;
            3'b101: outputs[5] = data_in;
            3'b110: outputs[6] = data_in;
            default: default_valid = 1'b1;
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: default_output_logic
// Function:  Generates the default_out signal when an invalid address is detected
// -----------------------------------------------------------------------------
module default_output_logic (
    input  wire data_in,
    input  wire default_valid,
    output wire default_out
);
    assign default_out = default_valid ? data_in : 1'b0;
endmodule