//SystemVerilog
module pause_frame_gen #(
    parameter QUANTUM = 16'hFFFF,
    parameter THRESHOLD = 16'h00FF
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        pause_req,
    input  wire [15:0] rx_pause,
    output reg  [7:0]  tx_data,
    output reg         tx_valid,
    output reg         tx_enable
);
    // State definitions with named states for better readability
    typedef enum logic [3:0] {
        ST_IDLE       = 4'h0,
        ST_PREAMBLE   = 4'h1,
        ST_SFD        = 4'h2,
        ST_MAC_HEADER = 4'h3,
        ST_ETH_TYPE   = 4'h4,
        ST_OPCODE     = 4'h5,
        ST_QUANTUM_VAL= 4'h6,
        ST_FCS        = 4'h7,
        ST_HOLD       = 4'h8
    } state_t;
    
    // ===== Control Path Signals =====
    state_t       state_r, next_state;
    reg    [3:0]  byte_cnt_r, next_byte_cnt;
    reg    [15:0] pause_timer_r, next_pause_timer;
    
    // ===== Data Path Signals =====
    reg    [31:0] crc_r, next_crc;
    reg    [7:0]  next_tx_data;
    reg           next_tx_valid, next_tx_enable;
    
    // ===== Pipeline Stage Register =====
    reg    [31:0] crc_stage1_r;
    reg    [7:0]  tx_data_stage1_r;
    
    // ===== Constants =====
    // Precomputed MAC header (DA+SA) - broken into segments for better readability
    localparam [47:0] DEST_MAC = {8'h01, 8'h80, 8'hC2, 8'h00, 8'h00, 8'h01};  // Dest MAC
    localparam [47:0] SRC_MAC  = {8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55};  // Src MAC
    localparam [15:0] ETH_TYPE_VAL = 16'h8808;  // Ethernet Type for PAUSE frame
    localparam [15:0] PAUSE_OPCODE = 16'h0001;  // PAUSE frame opcode
    
    // ===== CRC polynomial constant =====
    localparam [31:0] CRC_POLY = 32'h04C11DB7;
    
    // ===== Sequential Logic =====
    always @(posedge clk) begin
        if (rst) begin
            // Reset all state registers
            state_r       <= ST_IDLE;
            byte_cnt_r    <= 4'b0;
            crc_r         <= 32'hFFFFFFFF;
            pause_timer_r <= 16'b0;
            tx_data       <= 8'b0;
            tx_valid      <= 1'b0;
            tx_enable     <= 1'b0;
            
            // Reset pipeline registers
            crc_stage1_r     <= 32'hFFFFFFFF;
            tx_data_stage1_r <= 8'b0;
        end 
        else begin
            // Update main registers
            state_r       <= next_state;
            byte_cnt_r    <= next_byte_cnt;
            crc_r         <= next_crc;
            pause_timer_r <= next_pause_timer;
            tx_data       <= next_tx_data;
            tx_valid      <= next_tx_valid;
            tx_enable     <= next_tx_enable;
            
            // Update pipeline registers
            crc_stage1_r     <= crc_calc(crc_r, next_tx_data);
            tx_data_stage1_r <= next_tx_data;
        end
    end

    // ===== CRC calculation function =====
    // Modularized CRC calculation into a function for clarity
    function [31:0] crc_calc;
        input [31:0] crc_in;
        input [7:0]  data_in;
        
        reg [31:0] crc_temp;
        integer i;
        begin
            crc_temp = crc_in;
            for (i = 0; i < 8; i = i + 1) begin
                crc_temp = (crc_temp << 1) ^ 
                          ((crc_temp[31] ^ data_in[7-i]) ? CRC_POLY : 32'h0);
            end
            crc_calc = crc_temp;
        end
    endfunction

    // ===== Data Selection Logic =====
    // Separated data selection from state machine for cleaner structure
    function [7:0] get_frame_data;
        input state_t current_state;
        input [3:0]  byte_index;
        
        begin
            case(current_state)
                ST_PREAMBLE: 
                    get_frame_data = (byte_index < 7) ? 8'h55 : 8'hD5;
                
                ST_MAC_HEADER: begin
                    if (byte_index < 6)
                        get_frame_data = DEST_MAC[(5-byte_index)*8 +: 8];
                    else
                        get_frame_data = SRC_MAC[(11-byte_index)*8 +: 8];
                end
                
                ST_ETH_TYPE:
                    get_frame_data = (byte_index == 0) ? ETH_TYPE_VAL[15:8] : ETH_TYPE_VAL[7:0];
                
                ST_OPCODE:
                    get_frame_data = (byte_index == 0) ? PAUSE_OPCODE[15:8] : PAUSE_OPCODE[7:0];
                
                ST_QUANTUM_VAL:
                    get_frame_data = (byte_index[0]) ? QUANTUM[15:8] : QUANTUM[7:0];
                
                ST_FCS: begin
                    case(byte_index)
                        4'd0: get_frame_data = ~crc_r[31:24];
                        4'd1: get_frame_data = ~crc_r[23:16];
                        4'd2: get_frame_data = ~crc_r[15:8];
                        4'd3: get_frame_data = ~crc_r[7:0];
                        default: get_frame_data = 8'h00;
                    endcase
                end
                
                default: get_frame_data = 8'h00;
            endcase
        end
    endfunction

    // ===== Main State Machine Logic =====
    always @(*) begin
        // Default assignments to prevent latches
        next_state = state_r;
        next_byte_cnt = byte_cnt_r;
        next_pause_timer = pause_timer_r;
        next_tx_data = tx_data_stage1_r;  // Use pipelined data by default
        next_tx_valid = 1'b0;
        next_tx_enable = tx_enable;
        next_crc = crc_stage1_r;  // Use pipelined CRC by default
        
        case(state_r)
            ST_IDLE: begin
                next_tx_valid = 1'b0;
                next_tx_enable = 1'b0;
                
                // Determine if we need to send a PAUSE frame
                if (pause_req || (rx_pause > THRESHOLD)) begin
                    next_state = ST_PREAMBLE;
                    next_tx_enable = 1'b1;
                    next_crc = 32'hFFFFFFFF;
                    next_byte_cnt = 4'b0;
                end
            end

            ST_PREAMBLE: begin
                next_tx_data = get_frame_data(state_r, byte_cnt_r);
                next_tx_valid = 1'b1;
                
                if (byte_cnt_r == 4'd7) begin
                    next_state = ST_MAC_HEADER;
                    next_byte_cnt = 4'b0;
                end else begin
                    next_byte_cnt = byte_cnt_r + 4'b1;
                end
            end

            ST_MAC_HEADER: begin
                next_tx_data = get_frame_data(state_r, byte_cnt_r);
                next_tx_valid = 1'b1;
                
                if (byte_cnt_r == 4'd11) begin
                    next_state = ST_ETH_TYPE;
                    next_byte_cnt = 4'b0;
                end else begin
                    next_byte_cnt = byte_cnt_r + 4'b1;
                end
            end

            ST_ETH_TYPE: begin
                next_tx_data = get_frame_data(state_r, byte_cnt_r);
                next_tx_valid = 1'b1;
                
                if (byte_cnt_r == 4'd1) begin
                    next_state = ST_OPCODE;
                    next_byte_cnt = 4'b0;
                end else begin
                    next_byte_cnt = byte_cnt_r + 4'b1;
                end
            end

            ST_OPCODE: begin
                next_tx_data = get_frame_data(state_r, byte_cnt_r);
                next_tx_valid = 1'b1;
                
                if (byte_cnt_r == 4'd1) begin
                    next_state = ST_QUANTUM_VAL;
                    next_byte_cnt = 4'b0;
                end else begin
                    next_byte_cnt = byte_cnt_r + 4'b1;
                end
            end

            ST_QUANTUM_VAL: begin
                next_tx_data = get_frame_data(state_r, byte_cnt_r);
                next_tx_valid = 1'b1;
                
                if (byte_cnt_r == 4'd1) begin
                    next_state = ST_FCS;
                    next_byte_cnt = 4'b0;
                end else begin
                    next_byte_cnt = byte_cnt_r + 4'b1;
                end
            end

            ST_FCS: begin
                next_tx_data = get_frame_data(state_r, byte_cnt_r);
                next_tx_valid = 1'b1;
                
                // Special case for FCS - no CRC calculation needed
                if (byte_cnt_r == 4'd0) begin
                    next_crc = {crc_r[23:0], 8'hFF};
                end else if (byte_cnt_r == 4'd1) begin
                    next_crc = {crc_r[23:0], 8'hFF};
                end else if (byte_cnt_r == 4'd2) begin
                    next_crc = {crc_r[23:0], 8'hFF};
                end
                
                if (byte_cnt_r == 4'd3) begin
                    next_state = ST_HOLD;
                    next_byte_cnt = 4'b0;
                end else begin
                    next_byte_cnt = byte_cnt_r + 4'b1;
                end
            end

            ST_HOLD: begin
                next_tx_valid = 1'b0;
                next_tx_enable = 1'b0;
                
                if (pause_timer_r == 16'hFFFF) begin
                    next_state = ST_IDLE;
                    next_pause_timer = 16'b0;
                end else begin
                    next_pause_timer = pause_timer_r + 16'b1;
                end
            end
            
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end
endmodule