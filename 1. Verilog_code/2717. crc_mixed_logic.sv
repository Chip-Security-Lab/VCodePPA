module crc_mixed_logic (
    input clk,           // 添加了时钟输入
    input [15:0] data_in,
    output reg [7:0] crc
);
wire [7:0] comb_part = data_in[15:8] ^ data_in[7:0];
always @(posedge clk) begin
    crc <= {comb_part[6:0], comb_part[7]} ^ 8'h07;
end
endmodule