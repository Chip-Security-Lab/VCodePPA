//SystemVerilog
module integrity_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    output reg [7:0] crc_value,
    output reg integrity_error
);
    parameter [7:0] POLY = 8'hD5;
    parameter [7:0] EXPECTED_CRC = 8'h00;
    reg [7:0] shadow_crc;
    reg crc_feedback, shadow_feedback;
    
    always @(posedge clk) begin
        if (rst) begin
            crc_value <= 8'h00;
            shadow_crc <= 8'h00;
            integrity_error <= 1'b0;
        end else if (data_valid) begin
            // 计算反馈位
            crc_feedback = crc_value[7] ^ data[0];
            shadow_feedback = shadow_crc[7] ^ data[0];
            
            // 更新CRC值
            if (crc_feedback) begin
                crc_value <= {crc_value[6:0], 1'b0} ^ POLY;
            end else begin
                crc_value <= {crc_value[6:0], 1'b0};
            end
            
            // 更新影子CRC值
            if (shadow_feedback) begin
                shadow_crc <= {shadow_crc[6:0], 1'b0} ^ POLY;
            end else begin
                shadow_crc <= {shadow_crc[6:0], 1'b0};
            end
            
            // 检查完整性错误
            integrity_error <= (crc_value != shadow_crc);
        end
    end
endmodule