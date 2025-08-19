//SystemVerilog
module pause_frame_gen #(
    parameter QUANTUM = 16'hFFFF,
    parameter THRESHOLD = 16'h00FF
)(
    input clk,
    input rst,
    input pause_req,
    input [15:0] rx_pause,
    output reg [7:0] tx_data,
    output reg tx_valid,
    output reg tx_enable
);
    // Replace typedef enum with localparam
    localparam IDLE = 4'h0;
    localparam PREAMBLE = 4'h1; 
    localparam SFD = 4'h2;
    localparam MAC_HEADER = 4'h3;
    localparam ETH_TYPE = 4'h4;
    localparam OPCODE = 4'h5;
    localparam QUANTUM_VAL = 4'h6;
    localparam FCS = 4'h7;
    localparam HOLD = 4'h8;
    
    reg [3:0] state, next_state;
    reg [3:0] byte_cnt, next_byte_cnt;
    reg [31:0] crc_stage1, next_crc_stage1;
    reg [31:0] crc_stage2, next_crc_stage2;
    reg [31:0] crc_stage3, next_crc_stage3;
    reg [15:0] pause_timer, next_pause_timer;
    
    // Input pipeline registers
    reg pause_req_r1, pause_req_r2;
    reg [15:0] rx_pause_r1, rx_pause_r2;
    reg trigger_frame_stage1, trigger_frame_stage2;
    
    // Precomputed MAC header (DA+SA)
    wire [95:0] PAUSE_MAC = {
        8'h01, 8'h80, 8'hC2, 8'h00, 8'h00, 8'h01,  // Dest MAC
        8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55   // Src MAC
    };
    
    // Output pipeline registers
    reg [7:0] tx_data_stage1, tx_data_stage2, next_tx_data;
    reg tx_valid_stage1, tx_valid_stage2, next_tx_valid;
    reg tx_enable_stage1, tx_enable_stage2, next_tx_enable;
    
    // State pipeline registers
    reg [3:0] state_stage1, state_stage2;
    reg [3:0] byte_cnt_stage1, byte_cnt_stage2;

    // Register inputs - three-stage pipeline
    always @(posedge clk) begin
        if (rst) begin
            // Stage 1
            pause_req_r1 <= 0;
            rx_pause_r1 <= 0;
            
            // Stage 2
            pause_req_r2 <= 0;
            rx_pause_r2 <= 0;
            trigger_frame_stage1 <= 0;
            
            // Stage 3
            trigger_frame_stage2 <= 0;
        end else begin
            // Stage 1
            pause_req_r1 <= pause_req;
            rx_pause_r1 <= rx_pause;
            
            // Stage 2
            pause_req_r2 <= pause_req_r1;
            rx_pause_r2 <= rx_pause_r1;
            trigger_frame_stage1 <= pause_req_r2 || (rx_pause_r2 > THRESHOLD);
            
            // Stage 3
            trigger_frame_stage2 <= trigger_frame_stage1;
        end
    end
    
    // Split CRC calculation into stages for better timing
    // Stage 1: Process bits 7-5
    function [31:0] calc_crc_stage1;
        input [31:0] crc_in;
        input [7:0] data;
        reg [31:0] crc_tmp;
        begin
            crc_tmp = crc_in;
            
            // Bit 7
            if (crc_tmp[31] ^ data[7]) 
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            // Bit 6
            if (crc_tmp[31] ^ data[6])
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            // Bit 5
            if (crc_tmp[31] ^ data[5])
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            calc_crc_stage1 = crc_tmp;
        end
    endfunction
    
    // Stage 2: Process bits 4-2
    function [31:0] calc_crc_stage2;
        input [31:0] crc_in;
        input [7:0] data;
        reg [31:0] crc_tmp;
        begin
            crc_tmp = crc_in;
            
            // Bit 4
            if (crc_tmp[31] ^ data[4])
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            // Bit 3
            if (crc_tmp[31] ^ data[3])
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            // Bit 2
            if (crc_tmp[31] ^ data[2])
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            calc_crc_stage2 = crc_tmp;
        end
    endfunction
    
    // Stage 3: Process bits 1-0
    function [31:0] calc_crc_stage3;
        input [31:0] crc_in;
        input [7:0] data;
        reg [31:0] crc_tmp;
        begin
            crc_tmp = crc_in;
            
            // Bit 1
            if (crc_tmp[31] ^ data[1])
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            // Bit 0
            if (crc_tmp[31] ^ data[0])
                crc_tmp = (crc_tmp << 1) ^ 32'h04C11DB7;
            else
                crc_tmp = (crc_tmp << 1);
            
            calc_crc_stage3 = crc_tmp;
        end
    endfunction

    // Stage 1 of pipeline - next state logic
    always @(*) begin
        next_state = state;
        next_byte_cnt = byte_cnt;
        next_crc_stage1 = crc_stage1;
        next_pause_timer = pause_timer;
        next_tx_data = 8'h00;
        next_tx_valid = 0;
        next_tx_enable = tx_enable_stage2;
        
        case(state)
            IDLE: begin
                next_tx_valid = 0;
                if (trigger_frame_stage2) begin
                    next_state = PREAMBLE;
                    next_tx_enable = 1;
                    next_crc_stage1 = 32'hFFFFFFFF;
                    next_byte_cnt = 0;
                end
            end

            PREAMBLE: begin
                if (byte_cnt < 7) begin
                    next_tx_data = 8'h55;
                end else begin
                    next_tx_data = 8'hD5;
                end
                
                next_tx_valid = 1;
                
                if (byte_cnt == 7) begin
                    next_state = MAC_HEADER;
                    next_byte_cnt = 0;
                end else begin
                    next_byte_cnt = byte_cnt + 1;
                end
            end

            MAC_HEADER: begin
                next_tx_data = PAUSE_MAC[8*byte_cnt +: 8];
                next_tx_valid = 1;
                
                if (byte_cnt == 11) begin
                    next_state = ETH_TYPE;
                    next_byte_cnt = 0;
                end else begin
                    next_byte_cnt = byte_cnt + 1;
                end
            end

            ETH_TYPE: begin
                if (byte_cnt == 0) begin
                    next_tx_data = 8'h88;
                end else begin
                    next_tx_data = 8'h08;
                end
                
                next_tx_valid = 1;
                next_byte_cnt = byte_cnt + 1;
                
                if (byte_cnt == 1) begin
                    next_state = OPCODE;
                    next_byte_cnt = 0;
                end
            end

            OPCODE: begin
                if (byte_cnt == 0) begin
                    next_tx_data = 8'h00;
                end else begin
                    next_tx_data = 8'h01;  // Pause Opcode
                end
                
                next_tx_valid = 1;
                next_byte_cnt = byte_cnt + 1;
                
                if (byte_cnt == 1) begin
                    next_state = QUANTUM_VAL;
                    next_byte_cnt = 0;
                end
            end

            QUANTUM_VAL: begin
                if (byte_cnt[0]) begin
                    next_tx_data = QUANTUM[15:8];
                end else begin
                    next_tx_data = QUANTUM[7:0];
                end
                
                next_tx_valid = 1;
                next_byte_cnt = byte_cnt + 1;
                
                if (byte_cnt == 1) begin
                    next_state = FCS;
                    next_byte_cnt = 0;
                end
            end

            FCS: begin
                next_tx_data = ~crc_stage3[31:24];
                next_tx_valid = 1;
                next_crc_stage1 = {crc_stage3[23:0], 8'hFF};
                
                if (byte_cnt == 3) begin
                    next_state = HOLD;
                    next_byte_cnt = 0;
                end else begin
                    next_byte_cnt = byte_cnt + 1;
                end
            end

            HOLD: begin
                next_tx_valid = 0;
                next_tx_enable = 0;
                
                if (pause_timer == 16'hFFFF) begin
                    next_state = IDLE;
                    next_pause_timer = 0;
                end else begin
                    next_pause_timer = pause_timer + 1;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // CRC calculation pipeline
    always @(posedge clk) begin
        if (rst) begin
            crc_stage2 <= 32'hFFFFFFFF;
            crc_stage3 <= 32'hFFFFFFFF;
            next_crc_stage2 <= 32'hFFFFFFFF;
            next_crc_stage3 <= 32'hFFFFFFFF;
        end else begin
            // CRC pipeline stage 1
            if (tx_valid_stage1 && (state_stage1 != IDLE) && (state_stage1 != HOLD) && (state_stage1 != PREAMBLE || byte_cnt_stage1 == 7))
                next_crc_stage2 <= calc_crc_stage1(crc_stage1, tx_data_stage1);
            else
                next_crc_stage2 <= crc_stage1;
            
            // CRC pipeline stage 2
            if (tx_valid_stage2 && (state_stage2 != IDLE) && (state_stage2 != HOLD) && (state_stage2 != PREAMBLE || byte_cnt_stage2 == 7))
                next_crc_stage3 <= calc_crc_stage2(next_crc_stage2, tx_data_stage2);
            else
                next_crc_stage3 <= next_crc_stage2;
                
            // CRC pipeline stage 3
            if (tx_valid && (state != IDLE) && (state != HOLD) && (state != PREAMBLE || byte_cnt == 7))
                crc_stage3 <= calc_crc_stage3(next_crc_stage3, tx_data);
            else
                crc_stage3 <= next_crc_stage3;
                
            crc_stage2 <= next_crc_stage2;
        end
    end

    // State pipeline registers update
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            byte_cnt <= 0;
            crc_stage1 <= 32'hFFFFFFFF;
            pause_timer <= 0;
            
            state_stage1 <= IDLE;
            state_stage2 <= IDLE;
            byte_cnt_stage1 <= 0;
            byte_cnt_stage2 <= 0;
            
            tx_data <= 0;
            tx_valid <= 0;
            tx_enable <= 0;
            
            tx_data_stage1 <= 0;
            tx_data_stage2 <= 0;
            tx_valid_stage1 <= 0;
            tx_valid_stage2 <= 0;
            tx_enable_stage1 <= 0;
            tx_enable_stage2 <= 0;
        end else begin
            // Primary state update
            state <= next_state;
            byte_cnt <= next_byte_cnt;
            crc_stage1 <= next_crc_stage1;
            pause_timer <= next_pause_timer;
            
            // Pipeline state tracking
            state_stage1 <= state;
            state_stage2 <= state_stage1;
            byte_cnt_stage1 <= byte_cnt;
            byte_cnt_stage2 <= byte_cnt_stage1;
            
            // Output pipeline - stage 1
            tx_data_stage1 <= next_tx_data;
            tx_valid_stage1 <= next_tx_valid;
            tx_enable_stage1 <= next_tx_enable;
            
            // Output pipeline - stage 2
            tx_data_stage2 <= tx_data_stage1;
            tx_valid_stage2 <= tx_valid_stage1;
            tx_enable_stage2 <= tx_enable_stage1;
            
            // Final output registers
            tx_data <= tx_data_stage2;
            tx_valid <= tx_valid_stage2;
            tx_enable <= tx_enable_stage2;
        end
    end
endmodule