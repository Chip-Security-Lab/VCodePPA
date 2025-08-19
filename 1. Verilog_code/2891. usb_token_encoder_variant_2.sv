//SystemVerilog
module usb_token_encoder #(parameter ADDR_WIDTH = 7, PID_WIDTH = 4) (
    input wire clk, rst_n,
    input wire [PID_WIDTH-1:0] pid,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [3:0] endp,
    input wire encode_en,
    output reg [15:0] token_packet,
    output reg packet_ready
);
    reg [4:0] crc5_reg;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [3:0] endp_reg;
    reg encode_en_reg;
    
    // 输入信号寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= {ADDR_WIDTH{1'b0}};
            endp_reg <= 4'b0;
            encode_en_reg <= 1'b0;
        end else begin
            addr_reg <= addr;
            endp_reg <= endp;
            encode_en_reg <= encode_en;
        end
    end
    
    // CRC5计算模块
    reg [5:0] crc_temp;
    reg [10:0] data_to_crc;
    
    always @(*) begin
        data_to_crc = {addr_reg, endp_reg};
    end
    
    always @(*) begin
        crc_temp[0] = ^{endp_reg[3:0]};
        crc_temp[1] = ^{addr_reg[0], endp_reg[3], endp_reg[1:0]};
        crc_temp[2] = ^{addr_reg[2:0], endp_reg[2:1]};
        crc_temp[3] = ^{addr_reg[4:0], endp_reg[3:0]};
        crc_temp[4] = ^{addr_reg[6:0], endp_reg[3:0]};
    end
    
    // CRC寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc5_reg <= 5'b0;
        end else if (encode_en) begin
            crc5_reg <= crc_temp[4:0];
        end
    end
    
    // 令牌包组装
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_packet <= 16'h0000;
        end else if (encode_en_reg) begin
            token_packet <= {crc5_reg, endp_reg, addr_reg};
        end
    end
    
    // 包就绪信号控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_ready <= 1'b0;
        end else begin
            packet_ready <= encode_en_reg;
        end
    end
endmodule