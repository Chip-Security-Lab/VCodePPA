//SystemVerilog
module CRC_Filter #(parameter POLY=16'h8005) (
    input clk,
    input [7:0] data_in,
    output reg [15:0] crc_out
);
    reg [7:0] data_in_reg;
    reg [15:0] crc_out_internal;
    
    // Barrel shifter implementation
    wire [15:0] shifted_data;
    wire [7:0] xor_result = data_in_reg ^ crc_out_internal[15:8];
    
    // 8-bit left shift using barrel shifter
    assign shifted_data = {
        xor_result[0], xor_result[1], xor_result[2], xor_result[3],
        xor_result[4], xor_result[5], xor_result[6], xor_result[7],
        8'h00
    };
    
    wire [15:0] crc_partial = {crc_out_internal[7:0], 8'h00} ^ shifted_data;
    wire [15:0] poly_mask = (POLY & {16{crc_partial[15]}});
    
    always @(posedge clk) begin
        data_in_reg <= data_in;
        crc_out_internal <= crc_out;
        crc_out <= crc_partial ^ poly_mask;
    end
endmodule