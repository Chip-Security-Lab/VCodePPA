//SystemVerilog
module crc_with_masking(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] mask,
    input wire data_valid,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'h07;
    
    // 预先计算掩码数据
    wire [7:0] masked_data;
    assign masked_data = data & mask;
    
    // 预先计算XOR结果，提高时序性能
    wire feedback;
    assign feedback = crc[7] ^ masked_data[0];
    
    always @(posedge clk) begin
        if (rst) begin
            crc <= 8'h00;
        end
        else if (data_valid) begin
            // 使用if-else结构替代条件运算符
            if (feedback) begin
                crc <= {crc[6:0], 1'b0} ^ POLY;
            end
            else begin
                crc <= {crc[6:0], 1'b0};
            end
        end
    end
endmodule