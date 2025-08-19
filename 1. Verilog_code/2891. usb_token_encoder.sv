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
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_packet <= 16'h0000;
            packet_ready <= 1'b0;
        end else if (encode_en) begin
            crc5 = {^{addr[6:0], endp[3:0]}, ^{addr[4:0], endp[3:0]}, 
                  ^{addr[2:0], endp[2:1]}, ^{addr[0], endp[3], endp[1:0]}, 
                  ^{endp[3:0]}};
            token_packet <= {crc5, endp, addr};
            packet_ready <= 1'b1;
        end
    end
endmodule