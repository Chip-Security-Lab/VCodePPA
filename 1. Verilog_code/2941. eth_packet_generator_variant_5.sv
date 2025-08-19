//SystemVerilog
module eth_packet_generator (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [47:0] src_mac,
    input wire [47:0] dst_mac,
    input wire [15:0] ethertype,
    input wire [7:0] payload_pattern,
    input wire [10:0] payload_length,
    output reg [7:0] tx_data,
    output reg tx_valid,
    output reg tx_done
);
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DST_MAC = 3'd2;
    localparam SRC_MAC = 3'd3, ETHERTYPE = 3'd4, PAYLOAD = 3'd5, FCS = 3'd6;
    
    reg [2:0] state, next_state;
    reg [10:0] byte_count, next_byte_count;
    reg [7:0] next_tx_data;
    reg next_tx_valid;
    reg next_tx_done;
    
    // Registered input signals
    reg enable_r;
    reg [47:0] src_mac_r, dst_mac_r;
    reg [15:0] ethertype_r;
    reg [7:0] payload_pattern_r;
    reg [10:0] payload_length_r;
    
    // Register input signals to reduce input-to-register delay
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            enable_r <= 1'b0;
            src_mac_r <= 48'd0;
            dst_mac_r <= 48'd0;
            ethertype_r <= 16'd0;
            payload_pattern_r <= 8'd0;
            payload_length_r <= 11'd0;
        end else begin
            enable_r <= enable;
            src_mac_r <= src_mac;
            dst_mac_r <= dst_mac;
            ethertype_r <= ethertype;
            payload_pattern_r <= payload_pattern;
            payload_length_r <= payload_length;
        end
    end
    
    // Next state logic (combinational)
    always @(*) begin
        next_state = state;
        next_byte_count = byte_count;
        next_tx_data = tx_data;
        next_tx_valid = tx_valid;
        next_tx_done = tx_done;
        
        if (enable_r) begin
            case (state)
                IDLE: begin
                    next_state = PREAMBLE;
                    next_byte_count = 11'd0;
                    next_tx_valid = 1'b1;
                    next_tx_done = 1'b0;
                end
                
                PREAMBLE: begin
                    if (byte_count < 7) begin
                        next_tx_data = 8'h55;
                    end else begin
                        next_tx_data = 8'hD5;
                    end
                    
                    next_byte_count = byte_count + 1'b1;
                    if (byte_count == 7) begin
                        next_state = DST_MAC;
                        next_byte_count = 11'd0;
                    end
                end
                
                DST_MAC: begin
                    next_tx_data = dst_mac_r[47-8*byte_count -: 8];
                    next_byte_count = byte_count + 1'b1;
                    if (byte_count == 5) begin
                        next_state = SRC_MAC;
                        next_byte_count = 11'd0;
                    end
                end
                
                SRC_MAC: begin
                    next_tx_data = src_mac_r[47-8*byte_count -: 8];
                    next_byte_count = byte_count + 1'b1;
                    if (byte_count == 5) begin
                        next_state = ETHERTYPE;
                        next_byte_count = 11'd0;
                    end
                end
                
                ETHERTYPE: begin
                    if (byte_count == 0) begin
                        next_tx_data = ethertype_r[15:8];
                    end else begin
                        next_tx_data = ethertype_r[7:0];
                    end
                    
                    next_byte_count = byte_count + 1'b1;
                    if (byte_count == 1) begin
                        next_state = PAYLOAD;
                        next_byte_count = 11'd0;
                    end
                end
                
                PAYLOAD: begin
                    next_tx_data = payload_pattern_r + byte_count[7:0];
                    next_byte_count = byte_count + 1'b1;
                    if (byte_count == payload_length_r - 1) begin
                        next_state = FCS;
                        next_byte_count = 11'd0;
                    end
                end
                
                FCS: begin
                    // Simple placeholder for CRC
                    next_tx_data = 8'hAA;
                    next_byte_count = byte_count + 1'b1;
                    if (byte_count == 3) begin
                        next_state = IDLE;
                        next_tx_valid = 1'b0;
                        next_tx_done = 1'b1;
                    end
                end
            endcase
        end
    end
    
    // Register updates (sequential)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_count <= 11'd0;
            tx_valid <= 1'b0;
            tx_data <= 8'd0;
            tx_done <= 1'b0;
        end else begin
            state <= next_state;
            byte_count <= next_byte_count;
            tx_data <= next_tx_data;
            tx_valid <= next_tx_valid;
            tx_done <= next_tx_done;
        end
    end
endmodule