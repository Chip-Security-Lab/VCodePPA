//SystemVerilog
module auto_poly_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] data_len,
    output reg [15:0] crc_out
);
    // 多项式查找表，避免组合逻辑路径
    wire [15:0] poly_lut [0:2];
    assign poly_lut[0] = 16'h0007; // 8-bit CRC
    assign poly_lut[1] = 16'h8005; // 16-bit CRC
    assign poly_lut[2] = 16'h1021; // CCITT
    
    // 多项式选择逻辑使用寄存器存储，切割关键路径
    reg [15:0] polynomial_reg;
    reg [1:0] poly_sel;
    
    // 提前计算XOR结果的流水线优化
    reg crc_msb;
    reg data_bit;
    wire crc_msb_xor_data;
    wire [15:0] xor_result;
    
    // 多项式选择 - 使用更高效的多路复用器结构
    always @(posedge clk) begin
        if (rst) begin
            poly_sel <= 2'd2; // 默认CCITT
        end
        else begin
            case (data_len)
                8'd8:    poly_sel <= 2'd0;
                8'd16:   poly_sel <= 2'd1;
                default: poly_sel <= 2'd2;
            endcase
        end
    end
    
    // 流水线阶段1: 寄存多项式值和准备XOR输入
    always @(posedge clk) begin
        if (rst) begin
            polynomial_reg <= 16'h0000;
            crc_msb <= 1'b0;
            data_bit <= 1'b0;
        end
        else begin
            polynomial_reg <= poly_lut[poly_sel];
            crc_msb <= crc_out[15];
            data_bit <= data[0];
        end
    end
    
    // 使用显式的多路复用器结构替换三元运算符
    assign crc_msb_xor_data = crc_msb ^ data_bit;
    assign xor_result = crc_msb_xor_data ? polynomial_reg : 16'h0000;
    
    // 流水线阶段3: 最终CRC计算
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 16'h0000;
        end
        else begin
            crc_out <= {crc_out[14:0], 1'b0} ^ xor_result;
        end
    end
endmodule