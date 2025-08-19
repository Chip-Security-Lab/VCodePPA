//SystemVerilog
module reflected_input_crc(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h8005;
    
    // 反转数据位
    wire [7:0] reflected_data;
    assign reflected_data[0] = data_in[7];
    assign reflected_data[1] = data_in[6];
    assign reflected_data[2] = data_in[5];
    assign reflected_data[3] = data_in[4];
    assign reflected_data[4] = data_in[3];
    assign reflected_data[5] = data_in[2];
    assign reflected_data[6] = data_in[1];
    assign reflected_data[7] = data_in[0];
    
    // 流水线寄存器和中间信号
    reg data_valid_r;
    reg [7:0] reflected_data_r;
    reg [15:0] crc_out_shifted;
    reg xor_bit;
    reg [15:0] poly_sel;
    
    // 第一级流水线 - 存储输入和计算移位
    always @(posedge clk) begin
        if (reset) begin
            data_valid_r <= 1'b0;
            reflected_data_r <= 8'h0;
            crc_out_shifted <= 16'h0;
            xor_bit <= 1'b0;
        end
        else begin
            data_valid_r <= data_valid;
            reflected_data_r <= reflected_data;
            crc_out_shifted <= {crc_out[14:0], 1'b0};
            xor_bit <= crc_out[15] ^ reflected_data[0];
        end
    end
    
    // 第二级流水线 - 计算多项式选择
    always @(posedge clk) begin
        if (reset) begin
            poly_sel <= 16'h0;
        end
        else begin
            poly_sel <= xor_bit ? POLY : 16'h0000;
        end
    end
    
    // 最终CRC计算
    always @(posedge clk) begin
        if (reset) begin
            crc_out <= 16'hFFFF;
        end
        else if (data_valid_r) begin
            crc_out <= crc_out_shifted ^ poly_sel;
        end
    end
endmodule