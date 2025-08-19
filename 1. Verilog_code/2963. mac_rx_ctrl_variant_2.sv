//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: mac_rx_ctrl
//
// 深度流水线优化版MAC接收控制器模块
// 实现了更细粒度的流水线数据路径结构以提高最大工作频率
///////////////////////////////////////////////////////////////////////////////

module mac_rx_ctrl #(
    parameter MIN_FRAME_SIZE = 64,
    parameter MAX_FRAME_SIZE = 1522
)(
    input wire rx_clk,
    input wire sys_clk,
    input wire rst_n,
    input wire [7:0] phy_data,
    input wire data_valid,
    input wire crc_error,
    output reg [31:0] pkt_data,
    output reg pkt_valid,
    output reg [15:0] pkt_length,
    output reg rx_error
);
    // FSM states definition
    localparam IDLE       = 3'b000;
    localparam PREAMBLE   = 3'b001;
    localparam SFD        = 3'b010;
    localparam DATA       = 3'b011;
    localparam FCS        = 3'b100;
    localparam INTERFRAME = 3'b101;
    
    // FSM control signals
    reg [2:0] state_r, next_state;
    reg [2:0] state_stage1_r;
    
    // Data path registers
    reg [15:0] byte_count_r;
    reg [15:0] byte_count_stage1_r;
    reg [31:0] crc_result_r;
    
    // Clock domain crossing (CDC) signals
    reg [7:0] phy_data_meta, phy_data_sync;
    reg data_valid_meta, data_valid_sync;
    
    // Enhanced pipeline stages
    reg [7:0] rx_byte_stage1_r;
    reg rx_byte_valid_stage1_r;
    reg [7:0] rx_byte_stage2_r;
    reg rx_byte_valid_stage2_r;
    reg [15:0] byte_count_stage2_r;
    reg [7:0] rx_byte_stage3_r;
    reg rx_byte_valid_stage3_r;
    
    reg [7:0] data_assembly_stage2_r [0:3];  // 4 bytes assembly buffer for stage 2
    reg [1:0] byte_position_stage2_r;
    reg [31:0] data_assembly_stage3_r;
    reg [31:0] data_assembly_stage4_r;
    
    reg [15:0] length_counter_stage2_r;
    reg [15:0] length_counter_stage3_r;
    reg [15:0] length_counter_stage4_r;
    
    reg frame_active_stage2_r;
    reg frame_active_stage3_r;
    reg frame_active_stage4_r;
    reg frame_active_stage5_r;
    
    // Enhanced error detection pipeline
    reg crc_error_stage1_r;
    reg crc_error_stage2_r;
    reg crc_error_stage3_r;
    reg crc_error_detected_r;
    reg crc_error_detected_stage4_r;
    reg crc_error_detected_stage5_r;
    
    reg length_error_detected_r;
    reg length_error_detected_stage4_r;
    reg length_error_detected_stage5_r;
    
    // Frame boundary signals
    reg frame_end_stage1_r;
    reg frame_end_stage2_r;
    reg frame_end_stage3_r;
    reg frame_end_stage4_r;
    reg frame_end_stage5_r;
    
    //--------------------------------------------------------------------------
    // STAGE 0: Clock Domain Crossing (CDC) - Two-flip-flop synchronizer
    //--------------------------------------------------------------------------
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset metastability registers
            phy_data_meta <= 8'h0;
            phy_data_sync <= 8'h0;
            data_valid_meta <= 1'b0;
            data_valid_sync <= 1'b0;
            crc_error_stage1_r <= 1'b0;
        end else begin
            // Two-stage synchronization for metastability protection
            phy_data_meta <= phy_data;
            phy_data_sync <= phy_data_meta;
            data_valid_meta <= data_valid;
            data_valid_sync <= data_valid_meta;
            crc_error_stage1_r <= crc_error;
        end
    end

    //--------------------------------------------------------------------------
    // STAGE 1: FSM Control Logic and State Transitions
    //--------------------------------------------------------------------------
    always @(*) begin
        next_state = state_r;
        
        case(state_r)
            IDLE: begin
                if (data_valid_sync && phy_data_sync == 8'h55) 
                    next_state = PREAMBLE;
            end
            
            PREAMBLE: begin
                if (phy_data_sync == 8'hD5) 
                    next_state = SFD;
            end
            
            SFD: begin
                next_state = DATA;
            end
            
            DATA: begin
                if (!data_valid_sync || byte_count_r >= MAX_FRAME_SIZE) 
                    next_state = FCS;
            end
            
            FCS: begin
                next_state = INTERFRAME;
            end
            
            INTERFRAME: begin
                if (data_valid_sync)
                    next_state = PREAMBLE;
                else
                    next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // STAGE 2: State update and initial byte processing
    //--------------------------------------------------------------------------
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= IDLE;
            state_stage1_r <= IDLE;
            byte_count_r <= 16'h0;
            rx_byte_stage1_r <= 8'h0;
            rx_byte_valid_stage1_r <= 1'b0;
            frame_active_stage2_r <= 1'b0;
            frame_end_stage1_r <= 1'b0;
            crc_error_stage2_r <= 1'b0;
        end else begin
            state_r <= next_state;
            state_stage1_r <= state_r;
            crc_error_stage2_r <= crc_error_stage1_r;
            
            // Capture received byte for downstream processing
            rx_byte_stage1_r <= phy_data_sync;
            rx_byte_valid_stage1_r <= (state_r == DATA) && data_valid_sync;
            
            // Byte counter logic
            case(state_r)
                PREAMBLE: begin
                    byte_count_r <= (byte_count_r < 7) ? byte_count_r + 1'b1 : 16'h0;
                end
                
                DATA: begin   
                    byte_count_r <= byte_count_r + 1'b1;
                    frame_active_stage2_r <= 1'b1;
                end
                
                default: begin
                    byte_count_r <= 16'h0;
                    if (state_r == FCS || next_state == IDLE)
                        frame_active_stage2_r <= 1'b0;
                end
            endcase
            
            // Detect frame end - split into separate pipeline stage
            frame_end_stage1_r <= (state_r == DATA && next_state == FCS);
        end
    end

    //--------------------------------------------------------------------------
    // STAGE 3: Initial error detection and byte processing
    //--------------------------------------------------------------------------
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count_stage1_r <= 16'h0;
            rx_byte_stage2_r <= 8'h0;
            rx_byte_valid_stage2_r <= 1'b0;
            byte_count_stage2_r <= 16'h0;
            length_error_detected_r <= 1'b0;
            frame_active_stage3_r <= 1'b0;
            frame_end_stage2_r <= 1'b0;
            crc_error_stage3_r <= 1'b0;
        end else begin
            // Forward state from stage 2
            byte_count_stage1_r <= byte_count_r;
            rx_byte_stage2_r <= rx_byte_stage1_r;
            rx_byte_valid_stage2_r <= rx_byte_valid_stage1_r;
            byte_count_stage2_r <= byte_count_stage1_r;
            frame_active_stage3_r <= frame_active_stage2_r;
            frame_end_stage2_r <= frame_end_stage1_r;
            crc_error_stage3_r <= crc_error_stage2_r;
            
            // Error condition detection - stage 1
            if (frame_end_stage1_r) begin
                length_error_detected_r <= (byte_count_r < MIN_FRAME_SIZE);
            end
        end
    end

    //--------------------------------------------------------------------------
    // STAGE 4: Byte assembly into words - part 1
    //--------------------------------------------------------------------------
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_byte_stage3_r <= 8'h0;
            rx_byte_valid_stage3_r <= 1'b0;
            byte_position_stage2_r <= 2'b00;
            length_counter_stage2_r <= 16'h0;
            frame_end_stage3_r <= 1'b0;
            crc_error_detected_r <= 1'b0;
        end else begin
            // Forward data from previous stage
            rx_byte_stage3_r <= rx_byte_stage2_r;
            rx_byte_valid_stage3_r <= rx_byte_valid_stage2_r;
            frame_end_stage3_r <= frame_end_stage2_r;
            
            // Data assembly position tracking
            if (state_stage1_r == IDLE || state_stage1_r == INTERFRAME) begin
                byte_position_stage2_r <= 2'b00;
            end else if (rx_byte_valid_stage2_r) begin
                byte_position_stage2_r <= byte_position_stage2_r + 1'b1;
            end
            
            // Store byte in appropriate position
            if (rx_byte_valid_stage2_r) begin
                data_assembly_stage2_r[byte_position_stage2_r] <= rx_byte_stage2_r;
            end
            
            // Packet length tracking with clear condition
            if (state_stage1_r == IDLE || state_stage1_r == INTERFRAME) begin
                length_counter_stage2_r <= 16'h0;
            end else if (rx_byte_valid_stage2_r) begin
                length_counter_stage2_r <= length_counter_stage2_r + 1'b1;
            end
            
            // CRC error capture
            if (frame_end_stage2_r) begin
                crc_error_detected_r <= crc_error_stage3_r;
            end else if (state_stage1_r == IDLE) begin
                crc_error_detected_r <= 1'b0;
            end
        end
    end

    //--------------------------------------------------------------------------
    // STAGE 5: Byte assembly into words - part 2
    //--------------------------------------------------------------------------
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_assembly_stage3_r <= 32'h0;
            length_counter_stage3_r <= 16'h0;
            frame_active_stage4_r <= 1'b0;
            frame_end_stage4_r <= 1'b0;
            crc_error_detected_stage4_r <= 1'b0;
            length_error_detected_stage4_r <= 1'b0;
        end else begin
            // Forward data
            length_counter_stage3_r <= length_counter_stage2_r;
            frame_active_stage4_r <= frame_active_stage3_r;
            frame_end_stage4_r <= frame_end_stage3_r;
            crc_error_detected_stage4_r <= crc_error_detected_r;
            length_error_detected_stage4_r <= length_error_detected_r;
            
            // Assemble 32-bit word when we have 4 bytes or at end of packet
            if (byte_position_stage2_r == 2'b11 && rx_byte_valid_stage3_r) begin
                data_assembly_stage3_r <= {data_assembly_stage2_r[3], data_assembly_stage2_r[2], 
                                          data_assembly_stage2_r[1], data_assembly_stage2_r[0]};
            end else if (frame_end_stage3_r) begin
                // Handle partial word at end of frame - pad with zeros
                case (byte_position_stage2_r)
                    2'b00: data_assembly_stage3_r <= {24'h0, data_assembly_stage2_r[0]};
                    2'b01: data_assembly_stage3_r <= {16'h0, data_assembly_stage2_r[1], data_assembly_stage2_r[0]};
                    2'b10: data_assembly_stage3_r <= {8'h0, data_assembly_stage2_r[2], data_assembly_stage2_r[1], 
                                                    data_assembly_stage2_r[0]};
                    2'b11: data_assembly_stage3_r <= {data_assembly_stage2_r[3], data_assembly_stage2_r[2], 
                                                    data_assembly_stage2_r[1], data_assembly_stage2_r[0]};
                endcase
            end
        end
    end

    //--------------------------------------------------------------------------
    // STAGE 6: Final assembly and pipeline forwarding
    //--------------------------------------------------------------------------
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_assembly_stage4_r <= 32'h0;
            length_counter_stage4_r <= 16'h0;
            frame_active_stage5_r <= 1'b0;
            frame_end_stage5_r <= 1'b0;
            crc_error_detected_stage5_r <= 1'b0;
            length_error_detected_stage5_r <= 1'b0;
        end else begin
            // Forward data through pipeline
            data_assembly_stage4_r <= data_assembly_stage3_r;
            length_counter_stage4_r <= length_counter_stage3_r;
            frame_active_stage5_r <= frame_active_stage4_r;
            frame_end_stage5_r <= frame_end_stage4_r;
            crc_error_detected_stage5_r <= crc_error_detected_stage4_r;
            length_error_detected_stage5_r <= length_error_detected_stage4_r;
        end
    end

    //--------------------------------------------------------------------------
    // STAGE 7: Output registers for timing closure
    //--------------------------------------------------------------------------
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            pkt_data <= 32'h0;
            pkt_valid <= 1'b0;
            pkt_length <= 16'h0;
            rx_error <= 1'b0;
        end else begin
            // Register data assembly output
            pkt_data <= data_assembly_stage4_r;
            
            // Packet valid is asserted at end of frame and deasserted at idle
            if (frame_end_stage5_r) begin
                pkt_valid <= 1'b1;
                pkt_length <= length_counter_stage4_r;
            end else if (!frame_active_stage5_r) begin
                pkt_valid <= 1'b0;
            end
            
            // Error indication
            if (frame_end_stage5_r) begin
                rx_error <= crc_error_detected_stage5_r || length_error_detected_stage5_r;
            end else if (!frame_active_stage5_r) begin
                rx_error <= 1'b0;
            end
        end
    end
    
endmodule