module SPI_CRC_Checker #(
    parameter POLY_WIDTH = 8,
    parameter POLYNOMIAL = 8'h07      // CRC-8-CCITT
)(
    input clk, rst_n,
    input crc_en,
    input crc_init,
    output reg [POLY_WIDTH-1:0] crc_value,
    // SPI interface
    input sclk, cs_n,
    input mosi
);

reg [POLY_WIDTH-1:0] lfsr;
wire fb = lfsr[POLY_WIDTH-1] ^ mosi;
reg [POLY_WIDTH-1:0] poly_mask;

// Initialize
initial begin
    lfsr = {POLY_WIDTH{1'b1}};
    crc_value = {POLY_WIDTH{1'b1}};
    poly_mask = POLYNOMIAL;
end

always @(posedge sclk or posedge crc_init) begin
    if(crc_init) begin
        lfsr <= {POLY_WIDTH{1'b1}};
    end else if(!cs_n && crc_en) begin
        lfsr <= {lfsr[POLY_WIDTH-2:0], 1'b0} ^ 
                (fb ? POLYNOMIAL : {POLY_WIDTH{1'b0}});
    end
end

assign crc_value = lfsr;
endmodule