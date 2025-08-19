//SystemVerilog
// Top-level module: CRC Converter (Hierarchical, Modularized)

module crc_converter #(
    parameter DW = 8
)(
    input  wire            clk,
    input  wire            en,
    input  wire [DW-1:0]   data,
    output wire [DW-1:0]   crc_out
);

    // Internal CRC register
    reg [DW-1:0] crc_reg;

    // Internal wires for submodule connections
    wire [DW-1:0] crc_next;
    wire [DW-1:0] crc_xor;

    // Submodule: CRC Next State Generator
    crc_next_state #(.DW(DW)) u_crc_next_state (
        .crc_in  (crc_reg),
        .next_crc(crc_next)
    );

    // Submodule: CRC Data XOR
    crc_xor_data #(.DW(DW)) u_crc_xor_data (
        .crc_in   (crc_next),
        .data_in  (data),
        .crc_out  (crc_xor)
    );

    // Submodule: CRC Register Control
    crc_reg_ctrl #(.DW(DW)) u_crc_reg_ctrl (
        .clk      (clk),
        .en       (en),
        .crc_in   (crc_xor),
        .crc_init ({DW{1'b1}}),
        .crc_out  (crc_reg)
    );

    // Output assignment
    assign crc_out = crc_reg;

endmodule

// --------------------------------------------------------------------------
// Submodule: CRC Next State Generator
// Calculates the next CRC state based on current CRC value and polynomial
// Polynomial: x^8 + x^2 + x + 1 (0x07)
// --------------------------------------------------------------------------
module crc_next_state #(
    parameter DW = 8
)(
    input  wire [DW-1:0] crc_in,
    output wire [DW-1:0] next_crc
);
    assign next_crc = {crc_in[DW-2:0], 1'b0} ^ (crc_in[DW-1] ? 8'h07 : {DW{1'b0}});
endmodule

// --------------------------------------------------------------------------
// Submodule: CRC Data XOR
// Performs XOR of next CRC value with input data
// --------------------------------------------------------------------------
module crc_xor_data #(
    parameter DW = 8
)(
    input  wire [DW-1:0] crc_in,
    input  wire [DW-1:0] data_in,
    output wire [DW-1:0] crc_out
);
    assign crc_out = crc_in ^ data_in;
endmodule

// --------------------------------------------------------------------------
// Submodule: CRC Register Control
// Handles CRC register update and initialization
// --------------------------------------------------------------------------
module crc_reg_ctrl #(
    parameter DW = 8
)(
    input  wire            clk,
    input  wire            en,
    input  wire [DW-1:0]   crc_in,
    input  wire [DW-1:0]   crc_init,
    output reg  [DW-1:0]   crc_out
);
    // On enable, update CRC; otherwise, reset to initial value
    always @(posedge clk) begin
        if (en)
            crc_out <= crc_in;
        else
            crc_out <= crc_init;
    end
endmodule