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
    output wire [7:0] tx_data,
    output wire tx_valid,
    output wire tx_done
);
    // State encoding
    localparam [2:0] IDLE = 3'd0,
                     PREAMBLE = 3'd1,
                     DST_MAC = 3'd2,
                     SRC_MAC = 3'd3,
                     ETHERTYPE = 3'd4,
                     PAYLOAD = 3'd5,
                     FCS = 3'd6;
    
    // Internal control signals
    wire [2:0] state;
    wire [10:0] byte_count;
    wire state_change;
    wire [2:0] next_state;
    wire byte_count_reset;
    
    // Data generation control signals
    wire preamble_done, dst_mac_done, src_mac_done, ethertype_done, payload_done, fcs_done;
    
    // Connect the controller and datapath
    eth_packet_controller controller (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .byte_count(byte_count),
        .payload_length(payload_length),
        .preamble_done(preamble_done),
        .dst_mac_done(dst_mac_done),
        .src_mac_done(src_mac_done),
        .ethertype_done(ethertype_done),
        .payload_done(payload_done),
        .fcs_done(fcs_done),
        .state(state),
        .next_state(next_state),
        .state_change(state_change),
        .byte_count_reset(byte_count_reset),
        .tx_valid(tx_valid),
        .tx_done(tx_done)
    );
    
    eth_packet_datapath datapath (
        .clk(clk),
        .reset(reset),
        .state(state),
        .byte_count(byte_count),
        .byte_count_reset(byte_count_reset),
        .state_change(state_change),
        .next_state(next_state),
        .src_mac(src_mac),
        .dst_mac(dst_mac),
        .ethertype(ethertype),
        .payload_pattern(payload_pattern),
        .preamble_done(preamble_done),
        .dst_mac_done(dst_mac_done),
        .src_mac_done(src_mac_done),
        .ethertype_done(ethertype_done),
        .payload_done(payload_done),
        .fcs_done(fcs_done),
        .tx_data(tx_data)
    );
    
endmodule

module eth_packet_controller (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [10:0] byte_count,
    input wire [10:0] payload_length,
    input wire preamble_done,
    input wire dst_mac_done,
    input wire src_mac_done,
    input wire ethertype_done,
    input wire payload_done,
    input wire fcs_done,
    output reg [2:0] state,
    output reg [2:0] next_state,
    output reg state_change,
    output reg byte_count_reset,
    output reg tx_valid,
    output reg tx_done
);

    // State parameter definitions
    localparam [2:0] IDLE = 3'd0,
                     PREAMBLE = 3'd1,
                     DST_MAC = 3'd2,
                     SRC_MAC = 3'd3,
                     ETHERTYPE = 3'd4,
                     PAYLOAD = 3'd5,
                     FCS = 3'd6;
    
    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            next_state <= IDLE;
            state_change <= 1'b0;
            byte_count_reset <= 1'b0;
            tx_valid <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            state <= next_state;
            state_change <= 1'b0;
            byte_count_reset <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (enable) begin
                        next_state <= PREAMBLE;
                        state_change <= 1'b1;
                        byte_count_reset <= 1'b1;
                        tx_valid <= 1'b1;
                        tx_done <= 1'b0;
                    end
                end
                
                PREAMBLE: begin
                    if (preamble_done) begin
                        next_state <= DST_MAC;
                        state_change <= 1'b1;
                        byte_count_reset <= 1'b1;
                    end
                end
                
                DST_MAC: begin
                    if (dst_mac_done) begin
                        next_state <= SRC_MAC;
                        state_change <= 1'b1;
                        byte_count_reset <= 1'b1;
                    end
                end
                
                SRC_MAC: begin
                    if (src_mac_done) begin
                        next_state <= ETHERTYPE;
                        state_change <= 1'b1;
                        byte_count_reset <= 1'b1;
                    end
                end
                
                ETHERTYPE: begin
                    if (ethertype_done) begin
                        next_state <= PAYLOAD;
                        state_change <= 1'b1;
                        byte_count_reset <= 1'b1;
                    end
                end
                
                PAYLOAD: begin
                    if (payload_done) begin
                        next_state <= FCS;
                        state_change <= 1'b1;
                        byte_count_reset <= 1'b1;
                    end
                end
                
                FCS: begin
                    if (fcs_done) begin
                        next_state <= IDLE;
                        state_change <= 1'b1;
                        tx_valid <= 1'b0;
                        tx_done <= 1'b1;
                    end
                end
                
                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end
endmodule

module eth_packet_datapath (
    input wire clk,
    input wire reset,
    input wire [2:0] state,
    input wire state_change,
    input wire [2:0] next_state,
    input wire byte_count_reset,
    input wire [47:0] src_mac,
    input wire [47:0] dst_mac,
    input wire [15:0] ethertype,
    input wire [7:0] payload_pattern,
    output reg [10:0] byte_count,
    output wire preamble_done,
    output wire dst_mac_done,
    output wire src_mac_done,
    output wire ethertype_done,
    output wire payload_done,
    output wire fcs_done,
    output reg [7:0] tx_data
);

    // State parameter definitions
    localparam [2:0] IDLE = 3'd0,
                     PREAMBLE = 3'd1,
                     DST_MAC = 3'd2,
                     SRC_MAC = 3'd3,
                     ETHERTYPE = 3'd4,
                     PAYLOAD = 3'd5,
                     FCS = 3'd6;
    
    // Byte counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_count <= 11'd0;
        end else if (byte_count_reset) begin
            byte_count <= 11'd0;
        end else if (state != IDLE) begin
            byte_count <= byte_count + 1'b1;
        end
    end
    
    // Completion flags
    assign preamble_done = (state == PREAMBLE) && (byte_count == 7);
    assign dst_mac_done = (state == DST_MAC) && (byte_count == 5);
    assign src_mac_done = (state == SRC_MAC) && (byte_count == 5);
    assign ethertype_done = (state == ETHERTYPE) && (byte_count == 1);
    assign payload_done = (state == PAYLOAD) && (byte_count == 11'd0 - 1); // Placeholder - should use payload_length
    assign fcs_done = (state == FCS) && (byte_count == 3);
    
    // Data multiplexer
    always @(*) begin
        case (state)
            PREAMBLE:
                tx_data = (byte_count < 7) ? 8'h55 : 8'hD5;
                
            DST_MAC:
                tx_data = dst_mac[47-8*byte_count -: 8];
                
            SRC_MAC:
                tx_data = src_mac[47-8*byte_count -: 8];
                
            ETHERTYPE:
                tx_data = (byte_count == 0) ? ethertype[15:8] : ethertype[7:0];
                
            PAYLOAD:
                tx_data = payload_pattern + byte_count[7:0];
                
            FCS:
                tx_data = 8'hAA; // Simple placeholder for CRC
                
            default:
                tx_data = 8'd0;
        endcase
    end

endmodule

module eth_crc_generator (
    input wire clk,
    input wire reset,
    input wire data_valid,
    input wire [7:0] data_in,
    output reg [31:0] crc_out
);
    // CRC-32 polynomial: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
    // IEEE 802.3 standard polynomial: 0x04C11DB7
    parameter POLYNOMIAL = 32'h04C11DB7;
    
    reg [31:0] crc_reg;
    reg [31:0] next_crc;
    integer i;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            crc_reg <= 32'hFFFFFFFF;
        end else if (data_valid) begin
            crc_reg <= next_crc;
        end
    end
    
    always @(*) begin
        next_crc = crc_reg;
        if (data_valid) begin
            next_crc = {24'h0, data_in} ^ crc_reg;
            for (i = 0; i < 8; i = i + 1) begin
                if (next_crc[0])
                    next_crc = (next_crc >> 1) ^ POLYNOMIAL;
                else
                    next_crc = next_crc >> 1;
            end
        end
    end
    
    // Output the CRC (inverted and byte-swapped as per Ethernet standard)
    always @(*) begin
        crc_out = ~{crc_reg[7:0], crc_reg[15:8], crc_reg[23:16], crc_reg[31:24]};
    end
    
endmodule