//SystemVerilog
module multi_standard_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [1:0] crc_type, // 00: CRC8, 01: CRC16, 10: CRC32
    output reg [31:0] crc_out
);
    localparam [7:0] POLY8 = 8'hD5;
    localparam [15:0] POLY16 = 16'h1021;
    localparam [31:0] POLY32 = 32'h04C11DB7;
    
    // 中间流水线寄存器
    reg [31:0] crc_shift;
    reg crc_xor_bit;
    reg [31:0] poly_selected;
    
    // 第一级流水线：计算移位和选择多项式
    always @(posedge clk) begin
        if (rst) begin
            crc_shift <= 32'h0;
            crc_xor_bit <= 1'b0;
            poly_selected <= 32'h0;
        end
        else begin
            // 计算移位结果
            case (crc_type)
                2'b00: crc_shift[7:0] <= {crc_out[6:0], 1'b0};
                2'b01: crc_shift[15:0] <= {crc_out[14:0], 1'b0};
                2'b10: crc_shift <= {crc_out[30:0], 1'b0};
                default: crc_shift <= crc_out;
            endcase
            
            // 计算XOR控制位
            case (crc_type)
                2'b00: crc_xor_bit <= crc_out[7] ^ data[0];
                2'b01: crc_xor_bit <= crc_out[15] ^ data[0];
                2'b10: crc_xor_bit <= crc_out[31] ^ data[0];
                default: crc_xor_bit <= 1'b0;
            endcase
            
            // 根据CRC类型选择多项式
            case (crc_type)
                2'b00: poly_selected <= {24'h0, POLY8};
                2'b01: poly_selected <= {16'h0, POLY16};
                2'b10: poly_selected <= POLY32;
                default: poly_selected <= 32'h0;
            endcase
        end
    end
    
    // 第二级流水线：计算最终CRC结果
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 32'h0;
        end
        else begin
            case (crc_type)
                2'b00: crc_out[7:0] <= crc_shift[7:0] ^ (crc_xor_bit ? poly_selected[7:0] : 8'h0);
                2'b01: crc_out[15:0] <= crc_shift[15:0] ^ (crc_xor_bit ? poly_selected[15:0] : 16'h0);
                2'b10: crc_out <= crc_shift ^ (crc_xor_bit ? poly_selected : 32'h0);
                default: crc_out <= crc_out;
            endcase
        end
    end
endmodule