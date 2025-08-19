//SystemVerilog
// Top-level module: Hierarchical cascaded shifter with modularized submodules

module CascadedShifter #(parameter STAGES=3, WIDTH=8) (
    input  wire                clk,
    input  wire                en,
    input  wire                serial_in,
    output wire                serial_out
);

    // Internal wires for inter-stage connections
    wire [STAGES:0]           stage_chain;

    assign stage_chain[0] = serial_in;

    // Instantiate all shift stages
    genvar gi;
    generate
        for(gi=0; gi<STAGES; gi=gi+1) begin : gen_shift_stage
            ShiftStage #(
                .WIDTH(WIDTH)
            ) u_shift_stage (
                .clk(clk),
                .en(en),
                .serial_in(stage_chain[gi]),
                .serial_out(stage_chain[gi+1])
            );
        end
    endgenerate

    assign serial_out = stage_chain[STAGES];

endmodule

//======================================================================
// ShiftStage: Single shift stage (encapsulates buffer and output extraction)
//======================================================================
module ShiftStage #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                en,
    input  wire                serial_in,
    output wire                serial_out
);
    // Internal connection
    wire [WIDTH-1:0] shift_reg_out;

    // Shift register submodule (serial-in, parallel-out)
    ShiftRegister #(.WIDTH(WIDTH)) u_shift_register (
        .clk(clk),
        .en(en),
        .serial_in(serial_in),
        .reg_out(shift_reg_out)
    );

    // Output extraction submodule (MSB out)
    MSBExtractor #(.WIDTH(WIDTH)) u_msb_extractor (
        .data_in(shift_reg_out),
        .msb_out(serial_out)
    );

endmodule

//======================================================================
// ShiftRegister: Parameterized serial-in, parallel-out shift register
//======================================================================
// Function: Receives serial input, shifts into register, provides parallel output
module ShiftRegister #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                en,
    input  wire                serial_in,
    output reg  [WIDTH-1:0]    reg_out
);
    always @(posedge clk) begin
        if (en)
            reg_out <= {reg_out[WIDTH-2:0], serial_in};
    end
endmodule

//======================================================================
// MSBExtractor: Extracts the MSB from parallel data as serial output
//======================================================================
// Function: Outputs the most significant bit of data_in as msb_out
module MSBExtractor #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0]    data_in,
    output wire                msb_out
);
    assign msb_out = data_in[WIDTH-1];
endmodule