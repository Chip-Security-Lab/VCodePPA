module eth_mac_tx #(parameter DATA_WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire tx_en,
    input wire [DATA_WIDTH-1:0] tx_data,
    input wire [47:0] src_mac,
    input wire [47:0] dst_mac,
    output reg [DATA_WIDTH-1:0] phy_tx_data,
    output reg phy_tx_en
);
    localparam IDLE = 2'b00, PREAMBLE = 2'b01, HEADER = 2'b10, PAYLOAD = 2'b11;
    reg [1:0] state, next_state;
    reg [3:0] byte_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            byte_cnt <= 0;
            phy_tx_en <= 0;
            phy_tx_data <= 0;
        end else begin
            state <= next_state;
            if (state == PREAMBLE) begin
                phy_tx_en <= 1;
                phy_tx_data <= (byte_cnt < 7) ? 8'h55 : 8'hD5;
                byte_cnt <= byte_cnt + 1;
            end else if (state == HEADER) begin
                byte_cnt <= byte_cnt + 1;
                phy_tx_data <= (byte_cnt < 6) ? dst_mac[8*(5-byte_cnt) +: 8] : 
                               (byte_cnt < 12) ? src_mac[8*(11-byte_cnt) +: 8] : tx_data;
            end
        end
    end
endmodule