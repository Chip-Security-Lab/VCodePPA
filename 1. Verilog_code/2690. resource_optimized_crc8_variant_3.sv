//SystemVerilog
module resource_optimized_crc8(
    input wire clk,
    input wire rst,
    input wire data_bit,
    input wire bit_valid,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'hD5;
    wire feedback = crc[7] ^ data_bit;
    
    always @(posedge clk) begin
        crc <= (rst) ? 8'h00 : 
               (bit_valid) ? (feedback ? {crc[6:0], 1'b0} ^ POLY : {crc[6:0], 1'b0}) : 
               crc;
    end
endmodule