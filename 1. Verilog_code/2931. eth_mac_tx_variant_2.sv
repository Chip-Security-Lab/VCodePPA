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
    // 状态定义
    localparam IDLE = 2'b00, PREAMBLE = 2'b01, HEADER = 2'b10, PAYLOAD = 2'b11;
    reg [1:0] state, next_state;
    reg [3:0] byte_cnt;
    reg [3:0] next_byte_cnt;
    reg next_phy_tx_en;
    reg [DATA_WIDTH-1:0] next_phy_tx_data;
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            byte_cnt <= 4'b0;
            phy_tx_en <= 1'b0;
            phy_tx_data <= {DATA_WIDTH{1'b0}};
        end else begin
            state <= next_state;
            byte_cnt <= next_byte_cnt;
            phy_tx_en <= next_phy_tx_en;
            phy_tx_data <= next_phy_tx_data;
        end
    end
    
    // 状态转移逻辑 - 使用显式多路复用器
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = (tx_en) ? PREAMBLE : IDLE;
            end
            PREAMBLE: begin
                next_state = (byte_cnt == 7) ? HEADER : PREAMBLE;
            end
            HEADER: begin
                next_state = (byte_cnt == 13) ? PAYLOAD : HEADER;
            end
            PAYLOAD: begin
                next_state = (~tx_en) ? IDLE : PAYLOAD;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // 字节计数器控制逻辑 - 使用显式多路复用器
    always @(*) begin
        case (state)
            IDLE: begin
                next_byte_cnt = 4'b0;
            end
            PREAMBLE: begin
                next_byte_cnt = byte_cnt + 1'b1;
            end
            HEADER: begin
                next_byte_cnt = byte_cnt + 1'b1;
            end
            PAYLOAD: begin
                next_byte_cnt = byte_cnt;
            end
            default: begin
                next_byte_cnt = 4'b0;
            end
        endcase
    end
    
    // 输出控制 - tx使能信号 - 使用显式多路复用器
    always @(*) begin
        case (state)
            IDLE: begin
                next_phy_tx_en = 1'b0;
            end
            PREAMBLE: begin
                next_phy_tx_en = 1'b1;
            end
            HEADER: begin
                next_phy_tx_en = 1'b1;
            end
            PAYLOAD: begin
                next_phy_tx_en = 1'b1;
            end
            default: begin
                next_phy_tx_en = 1'b0;
            end
        endcase
    end
    
    // 输出控制 - 数据生成逻辑 - 使用显式多路复用器
    always @(*) begin
        case (state)
            IDLE: begin
                next_phy_tx_data = {DATA_WIDTH{1'b0}};
            end
            PREAMBLE: begin
                case (byte_cnt)
                    4'd7: next_phy_tx_data = 8'hD5;
                    default: next_phy_tx_data = 8'h55;
                endcase
            end
            HEADER: begin
                if (byte_cnt < 6) begin
                    next_phy_tx_data = dst_mac[8*(5-byte_cnt) +: 8];
                end else if (byte_cnt < 12) begin
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