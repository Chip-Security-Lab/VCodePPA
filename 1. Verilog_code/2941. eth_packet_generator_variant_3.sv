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
    // State definitions
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DST_MAC = 3'd2;
    localparam SRC_MAC = 3'd3, ETHERTYPE = 3'd4, PAYLOAD = 3'd5, FCS = 3'd6;
    
    // State and counter registers
    reg [2:0] state, next_state;
    reg [10:0] byte_count, next_byte_count;
    
    // Registered input signals (moved registers forward)
    reg enable_r;
    reg [47:0] src_mac_r;
    reg [47:0] dst_mac_r;
    reg [15:0] ethertype_r;
    reg [7:0] payload_pattern_r;
    reg [10:0] payload_length_r;
    
    // Next-state output signals
    reg [7:0] next_tx_data;
    reg next_tx_valid;
    reg next_tx_done;
    
    // State transition control signals
    wire preamble_done, dst_mac_done, src_mac_done, ethertype_done, payload_done, fcs_done;
    
    // Optimized state transition flags
    assign preamble_done = (state == PREAMBLE) && (byte_count == 7);
    assign dst_mac_done = (state == DST_MAC) && (byte_count == 5);
    assign src_mac_done = (state == SRC_MAC) && (byte_count == 5);
    assign ethertype_done = (state == ETHERTYPE) && (byte_count == 1);
    assign payload_done = (state == PAYLOAD) && (byte_count == payload_length_r - 1);
    assign fcs_done = (state == FCS) && (byte_count == 3);
    
    // Register input signals
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
    
    // Next state logic - optimized with separate decisions
    always @(*) begin
        // Default assignment
        next_state = state;
        
        case (state)
            IDLE:      if (enable_r)      next_state = PREAMBLE;
            PREAMBLE:  if (preamble_done) next_state = DST_MAC;
            DST_MAC:   if (dst_mac_done)  next_state = SRC_MAC;
            SRC_MAC:   if (src_mac_done)  next_state = ETHERTYPE;
            ETHERTYPE: if (ethertype_done) next_state = PAYLOAD;
            PAYLOAD:   if (payload_done)  next_state = FCS;
            FCS:       if (fcs_done)      next_state = IDLE;
            default:   next_state = IDLE;
        endcase
    end
    
    // Byte counter logic - optimized to reset on state transitions
    always @(*) begin
        if (preamble_done || dst_mac_done || src_mac_done || 
            ethertype_done || payload_done || fcs_done || 
            (state == IDLE && enable_r)) begin
            next_byte_count = 11'd0;
        end else if (state != IDLE) begin
            next_byte_count = byte_count + 11'd1;
        end else begin
            next_byte_count = byte_count;
        end
    end
    
    // Output generation logic - optimized data selection
    always @(*) begin
        // Default assignments
        next_tx_valid = tx_valid;
        next_tx_done = tx_done;
        next_tx_data = tx_data;
        
        if (enable_r) begin
            if (state == IDLE) begin
                next_tx_valid = 1'b1;
                next_tx_done = 1'b0;
            end else if (fcs_done) begin
                next_tx_valid = 1'b0;
                next_tx_done = 1'b1;
            end
            
            case (state)
                PREAMBLE: next_tx_data = (byte_count != 7) ? 8'h55 : 8'hD5;
                DST_MAC:  next_tx_data = dst_mac_r[47:0] >> (8*(5-byte_count));
                SRC_MAC:  next_tx_data = src_mac_r[47:0] >> (8*(5-byte_count));
                ETHERTYPE: next_tx_data = (byte_count == 0) ? ethertype_r[15:8] : ethertype_r[7:0];
                PAYLOAD:  next_tx_data = payload_pattern_r + byte_count[7:0];
                FCS:      next_tx_data = 8'hAA;
                default:  next_tx_data = 8'h00;
            endcase
        end
    end
    
    // State and output registers
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
            tx_valid <= next_tx_valid;
            tx_data <= next_tx_data;
            tx_done <= next_tx_done;
        end
    end
endmodule