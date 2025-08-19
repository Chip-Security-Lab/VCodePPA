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
    reg [31:0] crc;
    reg [31:0] next_crc;
    reg [15:0] pause_timer, next_pause_timer;
    reg pause_req_reg, rx_pause_gt_threshold_reg;
    
    // Moved pipeline registers for input signals
    wire pause_req_masked = pause_req_reg || rx_pause_gt_threshold_reg;
    
    // Output pipeline registers
    reg [7:0] pre_tx_data;
    reg pre_tx_valid;
    reg pre_tx_enable;

    // Precomputed MAC header (DA+SA)
    wire [95:0] PAUSE_MAC = {
        8'h01, 8'h80, 8'hC2, 8'h00, 8'h00, 8'h01,  // Dest MAC
        8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55   // Src MAC
    };

    // Register input signals to reduce input delay
    always @(posedge clk) begin
        if (rst) begin
            pause_req_reg <= 0;
            rx_pause_gt_threshold_reg <= 0;
        end else begin
            pause_req_reg <= pause_req;
            rx_pause_gt_threshold_reg <= (rx_pause > THRESHOLD);
        end
    end

    // CRC calculation module
    function [31:0] calculate_crc;
        input [31:0] current_crc;
        input [7:0] data;
        reg [31:0] result;
        begin
            result = current_crc;
            
            if (result[31] ^ data[7])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            if (result[31] ^ data[6])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            if (result[31] ^ data[5])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            if (result[31] ^ data[4])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            if (result[31] ^ data[3])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            if (result[31] ^ data[2])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            if (result[31] ^ data[1])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            if (result[31] ^ data[0])
                result = (result << 1) ^ 32'h04C11DB7;
            else
                result = (result << 1);
                
            calculate_crc = result;
        end
    endfunction

    // State transition logic
    always @(*) begin
        next_state = state;
        next_byte_cnt = byte_cnt;
        next_pause_timer = pause_timer;
        
        case(state)
            IDLE: begin
                if (pause_req_masked) begin
                    next_state = PREAMBLE;
                end
            end

            PREAMBLE: begin
                if (byte_cnt == 7) begin
                    next_state = MAC_HEADER;
                    next_byte_cnt = 0;
                end else begin
                    next_byte_cnt = byte_cnt + 1;
                end
            end

            MAC_HEADER: begin
                if (byte_cnt == 11) begin
                    next_state = ETH_TYPE;
                    next_byte_cnt = 0;
                end else begin
                    next_byte_cnt = byte_cnt + 1;
                end
            end

            ETH_TYPE: begin
                next_byte_cnt = byte_cnt + 1;
                if (byte_cnt == 1) begin
                    next_state = OPCODE;
                end
            end

            OPCODE: begin
                next_byte_cnt = byte_cnt + 1;
                if (byte_cnt == 1) begin
                    next_state = QUANTUM_VAL;
                end
            end

            QUANTUM_VAL: begin
                next_byte_cnt = byte_cnt + 1;
                if (byte_cnt == 1) begin
                    next_state = FCS;
                end
            end

            FCS: begin
                if (byte_cnt == 3) begin
                    next_state = HOLD;
                    next_byte_cnt = 0;
                end else begin
                    next_byte_cnt = byte_cnt + 1;
                end
            end

            HOLD: begin
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

    // Output logic - modified to produce pre-registered outputs
    always @(*) begin
        pre_tx_valid = 0;
        pre_tx_enable = 0;
        pre_tx_data = 8'h00;
        next_crc = crc;
        
        case(state)
            IDLE: begin
                pre_tx_valid = 0;
                if (pause_req_masked) begin
                    pre_tx_enable = 1;
                    next_crc = 32'hFFFFFFFF;
                end
            end

            PREAMBLE: begin
                if (byte_cnt < 7) begin
                    pre_tx_data = 8'h55;
                end else begin
                    pre_tx_data = 8'hD5;
                end
                pre_tx_valid = 1;
                if (byte_cnt == 7) begin
                    next_crc = calculate_crc(crc, pre_tx_data);
                end
            end

            MAC_HEADER: begin
                pre_tx_data = PAUSE_MAC[8*byte_cnt +: 8];
                pre_tx_valid = 1;
                next_crc = calculate_crc(crc, pre_tx_data);
            end

            ETH_TYPE: begin
                if (byte_cnt == 0) begin
                    pre_tx_data = 8'h88;
                end else begin
                    pre_tx_data = 8'h08;
                end
                pre_tx_valid = 1;
                next_crc = calculate_crc(crc, pre_tx_data);
            end

            OPCODE: begin
                if (byte_cnt == 0) begin
                    pre_tx_data = 8'h00;
                end else begin
                    pre_tx_data = 8'h01;  // Pause Opcode
                end
                pre_tx_valid = 1;
                next_crc = calculate_crc(crc, pre_tx_data);
            end

            QUANTUM_VAL: begin
                if (byte_cnt[0]) begin
                    pre_tx_data = QUANTUM[15:8];
                end else begin
                    pre_tx_data = QUANTUM[7:0];
                end
                pre_tx_valid = 1;
                next_crc = calculate_crc(crc, pre_tx_data);
            end

            FCS: begin
                pre_tx_data = ~crc[31:24];
                pre_tx_valid = 1;
                next_crc = {crc[23:0], 8'hFF};
            end

            HOLD: begin
                pre_tx_valid = 0;
                pre_tx_enable = 0;
            end
            
            default: begin
                pre_tx_valid = 0;
                pre_tx_enable = 0;
            end
        endcase
    end

    // Sequential logic - modified for forward retiming
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            byte_cnt <= 0;
            crc <= 32'hFFFFFFFF;
            pause_timer <= 0;
            // Register output signals separately
            tx_data <= 0;
            tx_valid <= 0;
            tx_enable <= 0;
        end else begin
            state <= next_state;
            byte_cnt <= next_byte_cnt;
            crc <= next_crc;
            pause_timer <= next_pause_timer;
            // Register the output signals
            tx_data <= pre_tx_data;
            tx_valid <= pre_tx_valid;
            tx_enable <= pre_tx_enable;
        end
    end
endmodule