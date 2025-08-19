//SystemVerilog
module crc8_gen (
    input        clk,
    input        rst_n,
    input  [7:0] data_in,
    output reg [7:0] crc_out
);

// Internal signal for holding intermediate CRC value after combination
wire [7:0] crc_xor_comb;
wire [7:0] crc_shifted_comb;

//---------------------------------------------
// 1. CRC XOR with data_in (Combinational)
//---------------------------------------------
assign crc_xor_comb = crc_out ^ data_in;

//---------------------------------------------
// 2. CRC Shift and Polynomial XOR (Combinational)
//---------------------------------------------
assign crc_shifted_comb = {crc_xor_comb[6:0], 1'b0} ^ (crc_xor_comb[7] ? 8'h07 : 8'h00);

//---------------------------------------------
// 3. CRC Output Register Update (Register moved forward)
//---------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        crc_out <= 8'b0;
    else
        crc_out <= crc_shifted_comb;
end

endmodule