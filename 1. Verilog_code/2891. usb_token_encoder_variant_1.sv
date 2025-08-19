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
    reg [4:0] crc5;
    wire [4:0] crc5_calc;
    
    // 优化的CRC计算逻辑 - 消除冗余XOR操作
    assign crc5_calc[4] = ^{addr[6:0], endp[3:0]};
    assign crc5_calc[3] = ^{addr[4:0], endp[3:0]};
    assign crc5_calc[2] = ^{addr[2:0], endp[2:1]};
    assign crc5_calc[1] = addr[0] ^ endp[3] ^ endp[1] ^ endp[0];
    assign crc5_calc[0] = ^endp[3:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_packet <= 16'h0000;
            packet_ready <= 1'b0;
            crc5 <= 5'b00000;
        end else if (encode_en) begin
            // 直接使用CRC计算结果，移除不必要的补码操作
            crc5 <= crc5_calc;
            token_packet <= {crc5_calc, endp, addr};
            packet_ready <= 1'b1;
        end
    end
endmodule