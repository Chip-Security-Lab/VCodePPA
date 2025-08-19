//SystemVerilog
module CRC_Filter #(parameter POLY=16'h8005) (
    input clk,
    input [7:0] data_in,
    output reg [15:0] crc_out
);
    reg [7:0] data_reg;
    wire [15:0] poly_mask;
    
    // 组合逻辑计算
    assign poly_mask = POLY & {16{crc_out[15]}};
    
    // 合并的always块 - 同时处理数据寄存和CRC计算
    always @(posedge clk) begin
        data_reg <= data_in;
        crc_out <= {crc_out[7:0], 8'h00} ^ ((data_reg ^ crc_out[15:8]) << 8) ^ poly_mask;
    end
endmodule