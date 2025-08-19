module crc_converter #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] data,
    output reg [DW-1:0] crc
);
    wire [DW-1:0] next_crc = {crc[6:0], 1'b0} ^ (crc[7] ? 8'h07 : 0);
    
    always @(posedge clk) begin
        if(en) crc <= next_crc ^ data;
        else crc <= 8'hFF;
    end
endmodule
