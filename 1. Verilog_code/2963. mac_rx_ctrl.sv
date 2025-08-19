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
    // 使用参数替代typedef enum
    localparam IDLE = 3'b000;
    localparam PREAMBLE = 3'b001;
    localparam SFD = 3'b010;
    localparam DATA = 3'b011;
    localparam FCS = 3'b100;
    localparam INTERFRAME = 3'b101;
    
    reg [2:0] state, next_state;
    reg [15:0] byte_count;
    reg [31:0] crc_result;
    reg [7:0] sync_phy_data;
    reg sync_data_valid;

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
            state <= next_state;
            case(state)
                PREAMBLE: begin
                    byte_count <= (byte_count < 7) ? byte_count + 1 : 0;
                end
                
                DATA: begin   
                    byte_count <= byte_count + 1;
                    // 构建包数据
                    pkt_data <= {pkt_data[23:0], sync_phy_data};
                    
                    // 更新包长度
                    if (byte_count == 16'd0) begin
                        pkt_length <= 16'd1;
                    end else begin
                        pkt_length <= pkt_length + 1;
                    end
                end
                
                default: begin
                    byte_count <= 0;
                end
            endcase
            
            if (state == DATA && next_state == FCS) begin
                pkt_valid <= 1;
                // CRC检查
                if (crc_error) begin
                    rx_error <= 1;
                end
            end else if (next_state == IDLE) begin
                pkt_valid <= 0;
                rx_error <= 0;
            end
        end
    end

    always @(*) begin
        next_state = state;
        case(state)
            IDLE: begin
                if (sync_data_valid && sync_phy_data == 8'h55) 
                    next_state = PREAMBLE;
            end
            
            PREAMBLE: begin
                if (sync_phy_data == 8'hD5) 
                    next_state = SFD;
            end
            
            SFD: begin
                next_state = DATA;
            end
            
            DATA: begin
                if (!sync_data_valid || byte_count >= MAX_FRAME_SIZE) 
                    next_state = FCS;
            end
            
            FCS: begin
                next_state = INTERFRAME;
            end
            
            INTERFRAME: begin
                if (sync_data_valid) 
                    next_state = PREAMBLE;
                else
                    next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule