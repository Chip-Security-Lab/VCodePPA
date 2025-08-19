module crc_config_xor #(
    parameter WIDTH = 16,
    parameter INIT = 16'hFFFF,
    parameter FINAL_XOR = 16'h0000
)(
    input clk, en, 
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] crc
);
always @(posedge clk) begin
    if (en) begin
        crc <= (crc << 1) ^ (data ^ (crc[WIDTH-1] ? 16'h1021 : 0));
    end else begin
        crc <= INIT;
    end
end

assign crc_result = crc ^ FINAL_XOR;  // 最终输出级
endmodule