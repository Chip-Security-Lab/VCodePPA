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
    
    reg [2:0] state;
    reg [10:0] byte_count;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_count <= 11'd0;
            tx_valid <= 1'b0;
            tx_data <= 8'd0;
            tx_done <= 1'b0;
        end else if (enable) begin
            case (state)
                IDLE: begin
                    state <= PREAMBLE;
                    byte_count <= 11'd0;
                    tx_valid <= 1'b1;
                    tx_done <= 1'b0;
                end
                
                PREAMBLE: begin
                    tx_data <= (byte_count < 7) ? 8'h55 : 8'hD5;
                    byte_count <= byte_count + 1'b1;
                    if (byte_count == 7) begin
                        state <= DST_MAC;
                        byte_count <= 11'd0;
                    end
                end
                
                DST_MAC: begin
                    tx_data <= dst_mac[47-8*byte_count -: 8];
                    byte_count <= byte_count + 1'b1;
                    if (byte_count == 5) begin
                        state <= SRC_MAC;
                        byte_count <= 11'd0;
                    end
                end
                
                SRC_MAC: begin
                    tx_data <= src_mac[47-8*byte_count -: 8];
                    byte_count <= byte_count + 1'b1;
                    if (byte_count == 5) begin
                        state <= ETHERTYPE;
                        byte_count <= 11'd0;
                    end
                end
                
                ETHERTYPE: begin
                    tx_data <= (byte_count == 0) ? ethertype[15:8] : ethertype[7:0];
                    byte_count <= byte_count + 1'b1;
                    if (byte_count == 1) begin
                        state <= PAYLOAD;
                        byte_count <= 11'd0;
                    end
                end
                
                PAYLOAD: begin
                    tx_data <= payload_pattern + byte_count[7:0];
                    byte_count <= byte_count + 1'b1;
                    if (byte_count == payload_length - 1) begin
                        state <= FCS;
                        byte_count <= 11'd0;
                    end
                end
                
                FCS: begin
                    // Simple placeholder for CRC
                    tx_data <= 8'hAA;
                    byte_count <= byte_count + 1'b1;
                    if (byte_count == 3) begin
                        state <= IDLE;
                        tx_valid <= 1'b0;
                        tx_done <= 1'b1;
                    end
                end
            endcase
        end
    end
endmodule