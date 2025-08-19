//SystemVerilog
module crc8_serial (
    input clk, rst_n,
    input req,
    input [7:0] data_in,
    output reg [7:0] crc_out,
    output reg ack
);
    parameter POLY = 8'h07;
    
    reg processing;
    wire [8:0] next_crc;
    wire [8:0] poly_xor_data;
    wire [8:0] data_shifted;
    
    // 预计算常量表达式
    assign data_shifted = {data_in, 1'b0};
    assign poly_xor_data = POLY ^ data_shifted;
    
    // 提前计算下一状态
    assign next_crc = {crc_out[6:0], 1'b0} ^ (crc_out[7] ? poly_xor_data : data_shifted);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 8'hFF;
            ack <= 1'b0;
            processing <= 1'b0;
        end
        else begin
            if (req && !processing && !ack) begin
                crc_out <= next_crc[7:0];
                processing <= 1'b1;
                ack <= 1'b1;
            end
            else if (ack && !req) begin
                ack <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
endmodule