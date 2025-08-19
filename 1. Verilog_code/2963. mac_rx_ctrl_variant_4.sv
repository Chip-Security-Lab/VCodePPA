//SystemVerilog
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
    // 状态定义 - 独热码编码
    localparam IDLE       = 6'b000001;
    localparam PREAMBLE   = 6'b000010;
    localparam SFD        = 6'b000100;
    localparam DATA       = 6'b001000;
    localparam FCS        = 6'b010000;
    localparam INTERFRAME = 6'b100000;
    
    // 主状态寄存器
    reg [5:0] state_r, next_state;
    
    // 数据通路分段寄存器
    reg [15:0] byte_count_r;
    reg [31:0] crc_result_r;
    
    // CDC同步器信号
    reg [7:0] phy_data_meta, sync_phy_data_r;
    reg data_valid_meta, sync_data_valid_r;
    
    // 数据处理流水线寄存器
    reg [7:0] data_stage1_r;
    reg data_valid_stage1_r;
    reg [31:0] data_buffer_r;
    reg [15:0] length_counter_r;
    
    // 输出控制寄存器
    reg pkt_valid_r;
    reg rx_error_r;
    
    // 第一级：时钟域跨越 (CDC) 流水线
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            phy_data_meta <= 8'h0;
            data_valid_meta <= 1'b0;
            sync_phy_data_r <= 8'h0;
            sync_data_valid_r <= 1'b0;
        end else begin
            // 第一级CDC同步
            phy_data_meta <= phy_data;
            data_valid_meta <= data_valid;
            
            // 第二级CDC同步
            sync_phy_data_r <= phy_data_meta;
            sync_data_valid_r <= data_valid_meta;
        end
    end
    
    // 第二级：数据预处理流水线
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1_r <= 8'h0;
            data_valid_stage1_r <= 1'b0;
        end else begin
            // 保存同步后的数据以供后续处理
            data_stage1_r <= sync_phy_data_r;
            data_valid_stage1_r <= sync_data_valid_r;
        end
    end
    
    // 第三级：状态机控制流水线
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= IDLE;
        end else begin
            state_r <= next_state;
        end
    end
    
    // 第四级：数据处理流水线 - 字节计数和数据缓存
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count_r <= 16'h0;
            data_buffer_r <= 32'h0;
            length_counter_r <= 16'h0;
        end else begin
            // 字节计数逻辑
            case(state_r)
                PREAMBLE: begin
                    byte_count_r <= (byte_count_r < 7) ? byte_count_r + 1'b1 : 16'h0;
                end
                
                DATA: begin
                    byte_count_r <= byte_count_r + 1'b1;
                    
                    // 数据缓存更新 - 移位寄存器减少关键路径
                    data_buffer_r <= {data_buffer_r[23:0], data_stage1_r};
                    
                    // 分段的长度计算逻辑
                    length_counter_r <= (byte_count_r == 16'h0) ? 16'h1 : length_counter_r + 1'b1;
                end
                
                default: begin
                    byte_count_r <= 16'h0;
                end
            endcase
        end
    end
    
    // 第五级：输出控制流水线
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            pkt_valid_r <= 1'b0;
            rx_error_r <= 1'b0;
            crc_result_r <= 32'h0;
        end else begin
            // 输出控制信号生成
            if (state_r == DATA && next_state == FCS) begin
                pkt_valid_r <= 1'b1;
                rx_error_r <= crc_error;
            end else if (next_state == IDLE) begin
                pkt_valid_r <= 1'b0;
                rx_error_r <= 1'b0;
            end
        end
    end
    
    // 第六级：最终输出寄存器 - 减少输出抖动
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            pkt_data <= 32'h0;
            pkt_valid <= 1'b0;
            pkt_length <= 16'h0;
            rx_error <= 1'b0;
        end else begin
            // 输出寄存器更新，改善时序封闭性
            pkt_data <= data_buffer_r;
            pkt_valid <= pkt_valid_r;
            pkt_length <= length_counter_r;
            rx_error <= rx_error_r;
        end
    end
    
    // 状态转换逻辑 - 组合电路（拆分为独立模块减少逻辑深度）
    always @(*) begin
        // 默认保持当前状态
        next_state = state_r;
        
        case(state_r)
            IDLE: begin
                if (sync_data_valid_r && (sync_phy_data_r == 8'h55)) 
                    next_state = PREAMBLE;
            end
            
            PREAMBLE: begin
                if (sync_phy_data_r == 8'hD5) 
                    next_state = SFD;
            end
            
            SFD: begin
                next_state = DATA;
            end
            
            DATA: begin
                if (!sync_data_valid_r || (byte_count_r >= MAX_FRAME_SIZE)) 
                    next_state = FCS;
            end
            
            FCS: begin
                next_state = INTERFRAME;
            end
            
            INTERFRAME: begin
                next_state = sync_data_valid_r ? PREAMBLE : IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule