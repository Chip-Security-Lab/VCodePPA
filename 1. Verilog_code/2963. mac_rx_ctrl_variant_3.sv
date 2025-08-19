//SystemVerilog
//IEEE 1364-2005 Verilog
module mac_rx_ctrl #(
    parameter MIN_FRAME_SIZE = 64,
    parameter MAX_FRAME_SIZE = 1522
)(
    input rx_clk,
    input sys_clk,
    input rst_n,
    input [7:0] phy_data,
    input data_valid,
    input crc_error,
    output reg [31:0] pkt_data,
    output reg pkt_valid,
    output reg [15:0] pkt_length,
    output reg rx_error
);
    // 使用独冷编码替代二进制编码
    localparam IDLE       = 6'b111110;  // 独冷编码，最低位为0
    localparam PREAMBLE   = 6'b111101;  // 独冷编码，次低位为0
    localparam SFD        = 6'b111011;  // 独冷编码，第3位为0
    localparam DATA       = 6'b110111;  // 独冷编码，第4位为0
    localparam FCS        = 6'b101111;  // 独冷编码，第5位为0
    localparam INTERFRAME = 6'b011111;  // 独冷编码，最高位为0
    
    reg [5:0] state, next_state;
    reg [15:0] byte_count;
    reg [31:0] crc_result;
    reg [7:0] sync_phy_data;
    reg sync_data_valid;

    // 高扇出信号缓冲寄存器
    reg [5:0] next_state_buf1, next_state_buf2;
    reg [15:0] byte_count_buf1, byte_count_buf2;
    reg idle_match_buf1, idle_match_buf2;
    wire idle_match;
    
    assign idle_match = (state == IDLE);

    // 高扇出信号缓冲
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_buf1 <= IDLE;
            next_state_buf2 <= IDLE;
            byte_count_buf1 <= 16'h0;
            byte_count_buf2 <= 16'h0;
            idle_match_buf1 <= 1'b1;
            idle_match_buf2 <= 1'b1;
        end else begin
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state;
            byte_count_buf1 <= byte_count;
            byte_count_buf2 <= byte_count;
            idle_match_buf1 <= idle_match;
            idle_match_buf2 <= idle_match;
        end
    end

    // Clock domain crossing synchronizer
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_phy_data <= 8'h0;
            sync_data_valid <= 1'b0;
        end else begin
            sync_phy_data <= phy_data;
            sync_data_valid <= data_valid;
        end
    end

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            byte_count <= 0;
            pkt_valid <= 0;
            pkt_length <= 0;
            rx_error <= 0;
            crc_result <= 32'h0;
        end else begin
            state <= next_state_buf1;
            
            // 扁平化处理byte_count的逻辑
            if (state == PREAMBLE && byte_count_buf1 < 7) begin
                byte_count <= byte_count_buf1 + 1;
            end else if (state == DATA) begin
                byte_count <= byte_count_buf1 + 1;
                // 构建包数据
                pkt_data <= {pkt_data[23:0], sync_phy_data};
                
                // 更新包长度
                if (byte_count_buf2 == 16'd0) begin
                    pkt_length <= 16'd1;
                end else begin
                    pkt_length <= pkt_length + 1;
                end
            end else begin
                byte_count <= 0;
            end
            
            // 扁平化处理pkt_valid和rx_error的逻辑
            if (state == DATA && next_state_buf2 == FCS) begin
                pkt_valid <= 1;
                // CRC检查
                if (crc_error) begin
                    rx_error <= 1;
                end
            end else if (next_state_buf2 == IDLE) begin
                pkt_valid <= 0;
                rx_error <= 0;
            end
        end
    end

    always @(*) begin
        next_state = state;
        
        // 使用独冷编码的状态转换逻辑
        if (state == IDLE && sync_data_valid && sync_phy_data == 8'h55) begin
            next_state = PREAMBLE;
        end else if (state == PREAMBLE && sync_phy_data == 8'hD5) begin
            next_state = SFD;
        end else if (state == SFD) begin
            next_state = DATA;
        end else if (state == DATA && (!sync_data_valid || byte_count_buf1 >= MAX_FRAME_SIZE)) begin
            next_state = FCS;
        end else if (state == FCS) begin
            next_state = INTERFRAME;
        end else if (state == INTERFRAME && sync_data_valid) begin
            next_state = PREAMBLE;
        end else if (state == INTERFRAME && !sync_data_valid) begin
            next_state = IDLE;
        end else if (state != IDLE && state != PREAMBLE && state != SFD && 
                    state != DATA && state != FCS && state != INTERFRAME) begin
            next_state = IDLE;
        end
    end
endmodule