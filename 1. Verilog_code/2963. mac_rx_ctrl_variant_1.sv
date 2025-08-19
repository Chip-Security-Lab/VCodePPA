//SystemVerilog
//IEEE 1364-2005
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
    reg [15:0] byte_count, byte_count_next;
    reg [31:0] crc_result;
    reg [7:0] sync_phy_data, sync_phy_data_ff;
    reg sync_data_valid, sync_data_valid_ff;
    
    // 流水线寄存器
    reg [31:0] pkt_data_stage1;
    reg [15:0] pkt_length_next, pkt_length_stage1;
    reg pkt_valid_next, pkt_valid_stage1;
    reg rx_error_next, rx_error_stage1;
    reg [2:0] state_ff;
    reg [2:0] next_state_ff;

    // Clock domain crossing synchronizer - 双级触发器同步
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_phy_data <= 8'h0;
            sync_phy_data_ff <= 8'h0;
            sync_data_valid <= 1'b0;
            sync_data_valid_ff <= 1'b0;
        end else begin
            sync_phy_data_ff <= phy_data;
            sync_phy_data <= sync_phy_data_ff;
            sync_data_valid_ff <= data_valid;
            sync_data_valid <= sync_data_valid_ff;
        end
    end

    // 状态转移逻辑 - 组合逻辑部分（扁平化if-else结构）
    always @(*) begin
        next_state = state;
        byte_count_next = byte_count;
        pkt_length_next = pkt_length;
        pkt_valid_next = pkt_valid;
        rx_error_next = rx_error;
        
        // IDLE状态转换
        if (state == IDLE && sync_data_valid && sync_phy_data == 8'h55) begin
            next_state = PREAMBLE;
            byte_count_next = 0;
        end else if (state == IDLE) begin
            byte_count_next = 0;
        end
        
        // PREAMBLE状态转换
        if (state == PREAMBLE && sync_phy_data == 8'hD5) begin
            next_state = SFD;
            byte_count_next = (byte_count < 7) ? byte_count + 1 : 0;
        end else if (state == PREAMBLE) begin
            byte_count_next = (byte_count < 7) ? byte_count + 1 : 0;
        end
        
        // SFD状态转换
        if (state == SFD) begin
            next_state = DATA;
            byte_count_next = 0;
        end
        
        // DATA状态转换
        if (state == DATA && (!sync_data_valid || byte_count >= MAX_FRAME_SIZE)) begin
            next_state = FCS;
            byte_count_next = byte_count + 1;
            
            if (byte_count == 16'd0) begin
                pkt_length_next = 16'd1;
            end else begin
                pkt_length_next = pkt_length + 1;
            end
        end else if (state == DATA) begin
            byte_count_next = byte_count + 1;
            
            if (byte_count == 16'd0) begin
                pkt_length_next = 16'd1;
            end else begin
                pkt_length_next = pkt_length + 1;
            end
        end
        
        // FCS状态转换
        if (state == FCS) begin
            next_state = INTERFRAME;
            byte_count_next = 0;
            pkt_valid_next = 1;
            if (crc_error) begin
                rx_error_next = 1;
            end
        end
        
        // INTERFRAME状态转换
        if (state == INTERFRAME && sync_data_valid) begin
            next_state = PREAMBLE;
            byte_count_next = 0;
        end else if (state == INTERFRAME) begin
            next_state = IDLE;
            byte_count_next = 0;
        end
        
        // 默认情况处理
        if (state > INTERFRAME) begin
            next_state = IDLE;
            byte_count_next = 0;
        end
        
        // 状态转换为IDLE时的特殊处理
        if (next_state == IDLE && state != IDLE) begin
            pkt_valid_next = 0;
            rx_error_next = 0;
        end
    end
    
    // 数据通路流水线 - 第一级
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_ff <= IDLE;
            next_state_ff <= IDLE;
            pkt_data_stage1 <= 32'h0;
            pkt_length_stage1 <= 0;
            pkt_valid_stage1 <= 0;
            rx_error_stage1 <= 0;
        end else begin
            state_ff <= state;
            next_state_ff <= next_state;
            pkt_length_stage1 <= pkt_length_next;
            pkt_valid_stage1 <= pkt_valid_next;
            rx_error_stage1 <= rx_error_next;
            
            // 构建包数据
            if (state == DATA) begin
                pkt_data_stage1 <= {pkt_data[23:0], sync_phy_data};
            end else begin
                pkt_data_stage1 <= pkt_data;
            end
        end
    end
    
    // 数据通路流水线 - 第二级 (输出寄存器)
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            byte_count <= 0;
            pkt_data <= 32'h0;
            pkt_length <= 0;
            pkt_valid <= 0;
            rx_error <= 0;
            crc_result <= 32'h0;
        end else begin
            state <= next_state_ff;
            byte_count <= byte_count_next;
            pkt_data <= pkt_data_stage1;
            pkt_length <= pkt_length_stage1;
            pkt_valid <= pkt_valid_stage1;
            rx_error <= rx_error_stage1;
        end
    end
endmodule