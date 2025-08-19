//SystemVerilog
module reflected_input_crc(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h8005;
    wire [7:0] reflected_data;
    reg [15:0] next_crc;
    
    // 使用连续赋值实现位反转，更高效
    assign reflected_data = {data_in[0], data_in[1], data_in[2], data_in[3], 
                             data_in[4], data_in[5], data_in[6], data_in[7]};
    
    // 优化CRC计算逻辑
    always @(*) begin
        if (data_valid) begin
            // 直接使用条件操作符简化逻辑，减少MUX层级
            next_crc = {crc_out[14:0], 1'b0};
            if (crc_out[15] ^ reflected_data[0])
                next_crc = next_crc ^ POLY;
        end else begin
            next_crc = crc_out;
        end
    end
    
    // 更新CRC寄存器
    always @(posedge clk) begin
        crc_out <= reset ? 16'hFFFF : next_crc;
    end
endmodule