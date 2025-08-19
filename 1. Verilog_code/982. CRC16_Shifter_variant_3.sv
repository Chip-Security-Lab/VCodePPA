//SystemVerilog
// Top-level CRC16 Shifter module with hierarchical structure (optimized with forward register retiming)
module CRC16_Shifter #(parameter POLY=16'h8005) (
    input  wire        clk,
    input  wire        rst,
    input  wire        serial_in,
    output wire [15:0] crc_out
);

    wire [15:0] crc_comb;
    reg  [15:0] crc_reg;

    // CRC Next Value Calculation Module: Computes next CRC value from reg output
    CRC16_NextValue #(.POLY(POLY)) u_crc_nextvalue (
        .crc_current    (crc_reg),
        .serial_in      (serial_in),
        .crc_next       (crc_comb)
    );

    // Register update and reset logic (moved after combinational logic)
    always @(posedge clk or posedge rst) begin
        if (rst)
            crc_reg <= 16'hFFFF;
        else
            crc_reg <= crc_comb;
    end

    assign crc_out = crc_reg;

endmodule

// -----------------------------------------------------------------------------
// CRC16_NextValue
// Computes the next CRC value based on polynomial and serial input
// Parameterized for different polynomials
// -----------------------------------------------------------------------------
module CRC16_NextValue #(parameter POLY=16'h8005) (
    input  wire [15:0] crc_current,
    input  wire        serial_in,
    output wire [15:0] crc_next
);
    wire feedback;
    assign feedback = crc_current[15] ^ serial_in;
    assign crc_next = {crc_current[14:0], 1'b0} ^ (POLY & {16{feedback}});
endmodule