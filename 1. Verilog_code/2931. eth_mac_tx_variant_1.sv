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
    
    // 状态编码优化：使用单热编码以减少组合逻辑深度
    localparam [3:0] IDLE = 4'b0001, 
                    PREAMBLE = 4'b0010, 
                    HEADER = 4'b0100, 
                    PAYLOAD = 4'b1000;
    reg [3:0] state, next_state;
    
    // 计数器和缓冲寄存器
    reg [3:0] byte_cnt;
    reg [3:0] byte_cnt_buf;
    
    // MAC地址寄存缓存
    reg [47:0] dst_mac_reg, src_mac_reg;
    
    // 数据路径优化：预计算并复用
    reg [DATA_WIDTH-1:0] tx_data_reg;
    
    // 预计算preamble和header数据值，减少比较链
    wire is_last_preamble = (byte_cnt == 7);
    wire [DATA_WIDTH-1:0] preamble_val = is_last_preamble ? 8'hD5 : 8'h55;
    
    // 优化header数据选择逻辑
    wire header_phase1 = (byte_cnt < 6);
    wire [7:0] dst_mac_byte = dst_mac_reg[8*(5-(byte_cnt & 4'h7)) +: 8];
    wire [7:0] src_mac_byte = src_mac_reg[8*(11-(byte_cnt & 4'h7)) +: 8];
    
    // 优化后的数据选择逻辑，减少比较链
    always @(*) begin
        case (state)
            PREAMBLE: tx_data_reg = preamble_val;
            HEADER: tx_data_reg = header_phase1 ? dst_mac_byte : src_mac_byte;
            PAYLOAD: tx_data_reg = tx_data;
            default: tx_data_reg = 8'h00;
        endcase
    end
    
    // 优化状态转换逻辑
    always @(*) begin
        next_state = state; // 默认保持当前状态
        
        case (state)
            IDLE:     if (tx_en) next_state = PREAMBLE;
            PREAMBLE: if (byte_cnt == 8) next_state = HEADER;
            HEADER:   if (byte_cnt == 14) next_state = PAYLOAD;
            PAYLOAD:  if (!tx_en) next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end
    
    // 状态寄存器更新和输出生成
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            byte_cnt <= 4'h0;
            byte_cnt_buf <= 4'h0;
            phy_tx_en <= 1'b0;
            phy_tx_data <= {DATA_WIDTH{1'b0}};
            dst_mac_reg <= 48'h0;
            src_mac_reg <= 48'h0;
        end else begin
            // 更新状态
            state <= next_state;
            byte_cnt_buf <= byte_cnt;
            
            // 缓存MAC地址
            dst_mac_reg <= dst_mac;
            src_mac_reg <= src_mac;
            
            // 处理输出和计数器
            case (state)
                IDLE: begin
                    phy_tx_en <= 1'b0;
                    phy_tx_data <= {DATA_WIDTH{1'b0}};
                    byte_cnt <= 4'h0;
                end
                
                PREAMBLE: begin
                    phy_tx_en <= 1'b1;
                    phy_tx_data <= tx_data_reg;
                    if (byte_cnt < 4'h8)
                        byte_cnt <= byte_cnt + 4'h1;
                end
                
                HEADER: begin
                    phy_tx_en <= 1'b1;
                    phy_tx_data <= tx_data_reg;
                    if (byte_cnt < 4'hE)
                        byte_cnt <= byte_cnt + 4'h1;
                end
                
                PAYLOAD: begin
                    phy_tx_en <= 1'b1;
                    phy_tx_data <= tx_data_reg;
                end
                
                default: begin
                    phy_tx_en <= 1'b0;
                    phy_tx_data <= {DATA_WIDTH{1'b0}};
                    byte_cnt <= 4'h0;
                end
            endcase
        end
    end
endmodule