//SystemVerilog
module CRC_Compress #(parameter POLY=32'h04C11DB7) (
    input clk, en,
    input [31:0] data,
    output reg [31:0] crc
);
    // Combinational logic for CRC calculation
    wire poly_select = crc[31]^data[31];
    wire [31:0] next_crc = {crc[30:0], 1'b0} ^ (poly_select ? POLY : 0);
    
    // Single consolidated register stage after combinational logic
    always @(posedge clk) begin
        if(en) begin
            crc <= next_crc;
        end
    end
endmodule