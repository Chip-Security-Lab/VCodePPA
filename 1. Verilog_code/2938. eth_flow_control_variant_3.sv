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
    // State definitions
    localparam IDLE = 2'b00, GEN_HEADER = 2'b01, GEN_DATA = 2'b10, GEN_FCS = 2'b11;
    
    // State and counter registers
    reg [1:0] state, next_state;
    reg [3:0] byte_counter, next_byte_counter;
    
    // Output registers and their next state values
    reg next_pause_frame_gen;
    reg [15:0] next_pause_quanta;
    reg next_tx_en;
    reg [7:0] next_tx_data;

    // Sequential logic block - only performs register updates on clock edge
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_counter <= 4'd0;
            pause_frame_gen <= 1'b0;
            pause_quanta <= 16'd0;
            tx_en <= 1'b0;
            tx_data <= 8'h00;
        end else begin
            state <= next_state;
            byte_counter <= next_byte_counter;
            pause_frame_gen <= next_pause_frame_gen;
            pause_quanta <= next_pause_quanta;
            tx_en <= next_tx_en;
            tx_data <= next_tx_data;
        end
    end

    // Combinational logic block - calculates next state and output values
    always @(*) begin
        // Default: hold current values
        next_state = state;
        next_byte_counter = byte_counter;
        next_pause_frame_gen = pause_frame_gen;
        next_pause_quanta = pause_quanta;
        next_tx_en = tx_en;
        next_tx_data = tx_data;

        // FSM state machine logic
        case (state)
            IDLE: begin
                if (rx_buffer_almost_full) begin
                    next_state = GEN_HEADER;
                    next_pause_frame_gen = 1'b1;
                    next_pause_quanta = 16'hFFFF; // Max pause time
                    next_byte_counter = 4'd0;
                    next_tx_en = 1'b1;
                end
            end
            
            GEN_HEADER: begin
                next_byte_counter = byte_counter + 1;
                
                // Header generation combinational logic
                case (byte_counter)
                    4'd0: next_tx_data = 8'h01; // Multicast address for PAUSE
                    4'd1: next_tx_data = 8'h80;
                    4'd2: next_tx_data = 8'hC2;
                    4'd3: next_tx_data = 8'h00;
                    4'd4: next_tx_data = 8'h00;
                    4'd5: next_tx_data = 8'h01;
                    default: begin
                        next_tx_data = local_mac_addr[47:40]; // Source MAC
                        next_state = GEN_DATA;
                        next_byte_counter = 4'd0;
                    end
                endcase
            end
            
            GEN_DATA: begin
                // Data generation combinational logic
                next_byte_counter = byte_counter + 1;
                
                if (byte_counter < 5) begin
                    // Source MAC address bytes
                    next_tx_data = local_mac_addr[39-8*byte_counter -: 8];
                end else if (byte_counter == 5) begin
                    // EtherType high byte: 0x8808 (MAC Control)
                    next_tx_data = 8'h88;
                end else if (byte_counter == 6) begin
                    // EtherType low byte
                    next_tx_data = 8'h08;
                end else if (byte_counter == 7) begin
                    // PAUSE opcode high byte
                    next_tx_data = 8'h01;
                end else if (byte_counter == 8) begin
                    // PAUSE opcode low byte
                    next_tx_data = 8'h00;
                end else if (byte_counter == 9) begin
                    // PAUSE time high byte
                    next_tx_data = pause_quanta[15:8];
                end else begin
                    // PAUSE time low byte
                    next_tx_data = pause_quanta[7:0];
                    next_state = GEN_FCS;
                    next_byte_counter = 4'd0;
                end
            end
            
            GEN_FCS: begin
                // FCS generation combinational logic
                if (byte_counter < 3) begin
                    // Generate CRC bytes for the frame (simplified)
                    next_tx_data = 8'h00;
                    next_byte_counter = byte_counter + 1;
                end else begin
                    // Last CRC byte and transition back to IDLE
                    next_tx_data = 8'h00;
                    next_tx_en = 1'b0;
                    next_state = IDLE;
                    next_pause_frame_gen = 1'b0;
                end
            end
        endcase
    end
endmodule