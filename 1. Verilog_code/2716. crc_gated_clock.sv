module crc_gated_clock (
    input clk, en,
    input [7:0] data,
    output reg [15:0] crc
);
wire gated_clk = clk & en;

always @(posedge gated_clk) begin
    crc <= {crc[14:0], 1'b0} ^ 
          (crc[15] ? 16'h8005 : 0) ^
          {8'h00, data};
end
endmodule