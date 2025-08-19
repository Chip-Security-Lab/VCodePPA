//SystemVerilog
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
    
    // State and counter registers
    reg [1:0] next_state;
    reg [1:0] state;
    reg [3:0] next_byte_counter;
    reg [3:0] byte_counter;
    
    // Output registers
    reg pause_frame_gen_next;
    reg [15:0] pause_quanta_next;
    reg tx_en_next;
    reg [7:0] tx_data_next;
    
    // Parallel Prefix Adder for byte_counter increment
    // P: Propagate, G: Generate signals for Kogge-Stone adder
    wire [3:0] P, G;
    wire [3:0] PP1, GG1;
    wire [3:0] PP2, GG2;
    wire [3:0] sum;
    
    // Level 0: Initial P and G
    assign P = byte_counter | 4'b0001; // Propagate
    assign G = byte_counter & 4'b0001; // Generate
    
    // Level 1: First level of prefix computation
    assign PP1[0] = P[0];
    assign GG1[0] = G[0];
    assign PP1[1] = P[1] & P[0];
    assign GG1[1] = G[1] | (P[1] & G[0]);
    assign PP1[2] = P[2] & P[1];
    assign GG1[2] = G[2] | (P[2] & G[1]);
    assign PP1[3] = P[3] & P[2];
    assign GG1[3] = G[3] | (P[3] & G[2]);
    
    // Level 2: Second level of prefix computation
    assign PP2[0] = PP1[0];
    assign GG2[0] = GG1[0];
    assign PP2[1] = PP1[1];
    assign GG2[1] = GG1[1];
    assign PP2[2] = PP1[2] & PP1[0];
    assign GG2[2] = GG1[2] | (PP1[2] & GG1[0]);
    assign PP2[3] = PP1[3] & PP1[1];
    assign GG2[3] = GG1[3] | (PP1[3] & GG1[1]);
    
    // Final sum computation
    assign sum[0] = P[0] ^ 1'b1;
    assign sum[1] = P[1] ^ GG2[0];
    assign sum[2] = P[2] ^ GG2[1];
    assign sum[3] = P[3] ^ GG2[2];
    
    // Combinational logic for next state and outputs
    always @(*) begin
        // Default assignments (hold current values)
        next_state = state;
        next_byte_counter = byte_counter;
        pause_frame_gen_next = pause_frame_gen;
        pause_quanta_next = pause_quanta;
        tx_en_next = tx_en;
        tx_data_next = tx_data;
        
        case (state)
            IDLE: begin
                if (rx_buffer_almost_full) begin
                    next_state = GEN_HEADER;
                    pause_frame_gen_next = 1'b1;
                    pause_quanta_next = 16'hFFFF; // Max pause time
                    next_byte_counter = 4'd0;
                    tx_en_next = 1'b1;
                end
            end
            GEN_HEADER: begin
                next_byte_counter = sum; // Use parallel prefix adder result
                case (byte_counter)
                    4'd0: tx_data_next = 8'h01; // Multicast address for PAUSE
                    4'd1: tx_data_next = 8'h80;
                    4'd2: tx_data_next = 8'hC2;
                    4'd3: tx_data_next = 8'h00;
                    4'd4: tx_data_next = 8'h00;
                    4'd5: tx_data_next = 8'h01;
                    default: begin
                        tx_data_next = local_mac_addr[47:40]; // Source MAC
                        next_state = GEN_DATA;
                        next_byte_counter = 4'd0;
                    end
                endcase
            end
            GEN_DATA: begin
                // Continue with source MAC and EtherType
                if (byte_counter < 5) begin
                    tx_data_next = local_mac_addr[39-8*byte_counter -: 8];
                    next_byte_counter = sum; // Use parallel prefix adder result
                end else if (byte_counter == 5) begin
                    tx_data_next = 8'h88; // EtherType: 0x8808 (MAC Control)
                    next_byte_counter = sum; // Use parallel prefix adder result
                end else if (byte_counter == 6) begin
                    tx_data_next = 8'h08;
                    next_byte_counter = sum; // Use parallel prefix adder result
                end else if (byte_counter == 7) begin
                    tx_data_next = 8'h01; // PAUSE opcode
                    next_byte_counter = sum; // Use parallel prefix adder result
                end else if (byte_counter == 8) begin
                    tx_data_next = 8'h00;
                    next_byte_counter = sum; // Use parallel prefix adder result
                end else if (byte_counter == 9) begin
                    tx_data_next = pause_quanta[15:8]; // PAUSE time high byte
                    next_byte_counter = sum; // Use parallel prefix adder result
                end else begin
                    tx_data_next = pause_quanta[7:0]; // PAUSE time low byte
                    next_state = GEN_FCS;
                    next_byte_counter = 4'd0;
                end
            end
            GEN_FCS: begin
                // Generate CRC bytes for the frame
                if (byte_counter < 3) begin
                    tx_data_next = 8'h00; // Simplified CRC placeholder
                    next_byte_counter = sum; // Use parallel prefix adder result
                end else begin
                    tx_data_next = 8'h00;
                    tx_en_next = 1'b0;
                    next_state = IDLE;
                    pause_frame_gen_next = 1'b0;
                end
            end
        endcase
    end
    
    // Sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_counter <= 4'd0;
            pause_frame_gen <= 1'b0;
            pause_quanta <= 16'd0;
            tx_en <= 1'b0;
            tx_data <= 8'd0;
        end else begin
            state <= next_state;
            byte_counter <= next_byte_counter;
            pause_frame_gen <= pause_frame_gen_next;
            pause_quanta <= pause_quanta_next;
            tx_en <= tx_en_next;
            tx_data <= tx_data_next;
        end
    end
endmodule