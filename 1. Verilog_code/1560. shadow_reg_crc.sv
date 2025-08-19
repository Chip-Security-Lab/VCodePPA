module shadow_reg_crc #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW+3:0] reg_out  // [DW+3:DW]为CRC
);
    wire [3:0] crc = data_in[3:0] ^ data_in[7:4];
    always @(posedge clk) begin
        if(rst) reg_out <= 0;
        else if(en) reg_out <= {crc, data_in};
    end
endmodule