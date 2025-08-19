//SystemVerilog
module crc7_async_rst(
    input wire clk,
    input wire arst_n,
    input wire [6:0] data,
    output reg [6:0] crc_out
);
    localparam [6:0] POLY = 7'h09; // CRC-7: x^7 + x^3 + 1
    
    wire feedback = crc_out[6] ^ data[0];
    wire [6:0] next_crc = {crc_out[5:0], 1'b0} ^ {feedback, feedback & POLY[5], feedback & POLY[4], 
                           feedback & POLY[3], feedback & POLY[2], feedback & POLY[1], feedback & POLY[0]};
    
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            crc_out <= 7'h00;
        else
            crc_out <= next_crc;
    end
endmodule