//SystemVerilog
module init_value_crc8(
    input wire clock,
    input wire resetn,
    input wire [7:0] init_value,
    input wire init_load,
    input wire [7:0] data,
    input wire data_req,
    output reg data_ack,
    output reg [7:0] crc_out
);
    parameter [7:0] POLYNOMIAL = 8'hD5;
    
    wire [7:0] next_crc;
    wire crc_msb;
    wire data_bit;
    wire poly_sel;
    
    // State register for handshake control
    reg processing;
    
    // 优化比较逻辑
    assign crc_msb = crc_out[7];
    assign data_bit = data[0];
    assign poly_sel = crc_msb ^ data_bit;
    
    // 预计算CRC结果
    assign next_crc = {crc_out[6:0], 1'b0} ^ (poly_sel ? POLYNOMIAL : 8'h00);
    
    // Handshake logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            data_ack <= 1'b0;
            processing <= 1'b0;
        end
        else begin
            if (data_req && !processing) begin
                data_ack <= 1'b1;
                processing <= 1'b1;
            end
            else if (processing && data_ack) begin
                data_ack <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
    
    // CRC computation logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            crc_out <= 8'h00;
        end
        else begin
            if (init_load)
                crc_out <= init_value;
            else if (data_req && !processing)
                crc_out <= next_crc;
            // 保持当前值不需要显式赋值
        end
    end
endmodule