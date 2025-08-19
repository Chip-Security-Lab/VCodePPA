module eth_flow_control (
    input wire clk,
    input wire reset,
    input wire rx_buffer_almost_full,
    input wire [47:0] local_mac_addr,
    output reg pause_frame_gen,
    output reg [15:0] pause_quanta,
    output reg [7:0] tx_data,
    output reg tx_en
);
    localparam IDLE = 2'b00, GEN_HEADER = 2'b01, GEN_DATA = 2'b10, GEN_FCS = 2'b11;
    reg [1:0] state;
    reg [3:0] byte_counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            pause_frame_gen <= 1'b0;
            pause_quanta <= 16'd0;
            byte_counter <= 4'd0;
            tx_en <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (rx_buffer_almost_full) begin
                        state <= GEN_HEADER;
                        pause_frame_gen <= 1'b1;
                        pause_quanta <= 16'hFFFF; // Max pause time
                        byte_counter <= 4'd0;
                        tx_en <= 1'b1;
                    end
                end
                GEN_HEADER: begin
                    byte_counter <= byte_counter + 1;
                    case (byte_counter)
                        4'd0: tx_data <= 8'h01; // Multicast address for PAUSE
                        4'd1: tx_data <= 8'h80;
                        4'd2: tx_data <= 8'hC2;
                        4'd3: tx_data <= 8'h00;
                        4'd4: tx_data <= 8'h00;
                        4'd5: tx_data <= 8'h01;
                        default: begin
                            tx_data <= local_mac_addr[47:40]; // Source MAC
                            state <= GEN_DATA;
                            byte_counter <= 4'd0;
                        end
                    endcase
                end
                GEN_DATA: begin
                    // Continue with source MAC and EtherType
                    if (byte_counter < 5) begin
                        tx_data <= local_mac_addr[39-8*byte_counter -: 8];
                        byte_counter <= byte_counter + 1;
                    end else if (byte_counter == 5) begin
                        tx_data <= 8'h88; // EtherType: 0x8808 (MAC Control)
                        byte_counter <= byte_counter + 1;
                    end else if (byte_counter == 6) begin
                        tx_data <= 8'h08;
                        byte_counter <= byte_counter + 1;
                    end else if (byte_counter == 7) begin
                        tx_data <= 8'h01; // PAUSE opcode
                        byte_counter <= byte_counter + 1;
                    end else if (byte_counter == 8) begin
                        tx_data <= 8'h00;
                        byte_counter <= byte_counter + 1;
                    end else if (byte_counter == 9) begin
                        tx_data <= pause_quanta[15:8]; // PAUSE time high byte
                        byte_counter <= byte_counter + 1;
                    end else begin
                        tx_data <= pause_quanta[7:0]; // PAUSE time low byte
                        state <= GEN_FCS;
                        byte_counter <= 4'd0;
                    end
                end
                GEN_FCS: begin
                    // Generate CRC bytes for the frame
                    if (byte_counter < 3) begin
                        tx_data <= 8'h00; // Simplified CRC placeholder
                        byte_counter <= byte_counter + 1;
                    end else begin
                        tx_data <= 8'h00;
                        tx_en <= 1'b0;
                        state <= IDLE;
                        pause_frame_gen <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule