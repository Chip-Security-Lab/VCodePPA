//SystemVerilog
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
    reg [3:0] byte_cnt, next_byte_cnt;
    reg next_phy_tx_en;
    reg [DATA_WIDTH-1:0] next_phy_tx_data;
    
    // State register update
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Byte counter register update
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            byte_cnt <= 4'b0;
        end else begin
            byte_cnt <= next_byte_cnt;
        end
    end
    
    // Output registers update
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            phy_tx_en <= 1'b0;
            phy_tx_data <= {DATA_WIDTH{1'b0}};
        end else begin
            phy_tx_en <= next_phy_tx_en;
            phy_tx_data <= next_phy_tx_data;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = tx_en ? PREAMBLE : IDLE;
            end
            PREAMBLE: begin
                next_state = (byte_cnt == 4'd7) ? HEADER : PREAMBLE;
            end
            HEADER: begin
                next_state = (byte_cnt == 4'd13) ? PAYLOAD : HEADER;
            end
            PAYLOAD: begin
                next_state = tx_en ? PAYLOAD : IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Byte counter logic
    always @(*) begin
        case (state)
            IDLE: begin
                next_byte_cnt = 4'b0;
            end
            PREAMBLE, HEADER: begin
                next_byte_cnt = byte_cnt + 4'b1;
            end
            PAYLOAD: begin
                next_byte_cnt = byte_cnt;
            end
            default: begin
                next_byte_cnt = 4'b0;
            end
        endcase
    end
    
    // PHY TX enable logic
    always @(*) begin
        case (state)
            IDLE: begin
                next_phy_tx_en = 1'b0;
            end
            PREAMBLE, HEADER, PAYLOAD: begin
                next_phy_tx_en = 1'b1;
            end
            default: begin
                next_phy_tx_en = 1'b0;
            end
        endcase
    end
    
    // PHY TX data logic
    always @(*) begin
        case (state)
            IDLE: begin
                next_phy_tx_data = {DATA_WIDTH{1'b0}};
            end
            PREAMBLE: begin
                next_phy_tx_data = (byte_cnt == 4'd7) ? 8'hD5 : 8'h55;
            end
            HEADER: begin
                if (byte_cnt <= 4'd5) begin
                    next_phy_tx_data = dst_mac[8*(5-byte_cnt) +: 8];
                end else if (byte_cnt <= 4'd11) begin
                    next_phy_tx_data = src_mac[8*(11-byte_cnt) +: 8];
                end else begin
                    next_phy_tx_data = tx_data;
                end
            end
            PAYLOAD: begin
                next_phy_tx_data = tx_data;
            end
            default: begin
                next_phy_tx_data = {DATA_WIDTH{1'b0}};
            end
        endcase
    end
    
endmodule