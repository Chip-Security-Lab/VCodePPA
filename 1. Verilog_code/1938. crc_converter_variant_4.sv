//SystemVerilog
// Top-level CRC Converter Module
module crc_converter #(parameter DW=8) (
    input  wire             clk,
    input  wire             en,
    input  wire [DW-1:0]    data,
    output reg  [DW-1:0]    crc
);

    wire [DW-1:0] next_crc;
    wire [DW-1:0] crc_comb;

    // CRC Next Value Calculation Submodule
    crc_next_calc #(.DW(DW)) u_crc_next_calc (
        .crc_in (crc),
        .next_crc (next_crc)
    );

    // CRC Combination with Input Data Submodule
    crc_data_comb #(.DW(DW)) u_crc_data_comb (
        .next_crc (next_crc),
        .data_in  (data),
        .crc_comb (crc_comb)
    );

    // CRC Register Update Logic
    always @(posedge clk) begin
        if (en)
            crc <= crc_comb;
        else
            crc <= {DW{1'b1}}; // 8'hFF for DW=8
    end

endmodule

// ----------------------------------------------------------------------
// Submodule: crc_next_calc
// Function: Computes the next CRC value based on the current CRC
// ----------------------------------------------------------------------
module crc_next_calc #(parameter DW=8) (
    input  wire [DW-1:0] crc_in,
    output wire [DW-1:0] next_crc
);
    assign next_crc = {crc_in[DW-2:0], 1'b0} ^ (crc_in[DW-1] ? 8'h07 : {DW{1'b0}});
endmodule

// ----------------------------------------------------------------------
// Submodule: crc_data_comb
// Function: Combines the next CRC with input data to produce final CRC
// ----------------------------------------------------------------------
module crc_data_comb #(parameter DW=8) (
    input  wire [DW-1:0] next_crc,
    input  wire [DW-1:0] data_in,
    output wire [DW-1:0] crc_comb
);
    assign crc_comb = next_crc ^ data_in;
endmodule