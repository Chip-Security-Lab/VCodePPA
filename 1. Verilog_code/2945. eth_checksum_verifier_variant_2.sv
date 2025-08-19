//SystemVerilog
module eth_checksum_verifier (
    input wire clock,
    input wire reset,
    
    // Input interface with valid-ready handshake
    input wire [7:0] rx_byte,
    input wire rx_valid,
    output reg rx_ready,
    
    // Control signals with valid-ready handshake
    input wire packet_start,
    input wire packet_start_valid,
    output reg packet_start_ready,
    
    input wire packet_end,
    input wire packet_end_valid,
    output reg packet_end_ready,
    
    // Output interface with valid-ready handshake
    output reg checksum_ok,
    output reg checksum_valid,
    input wire checksum_ready
);
    // Main state and checksum registers
    reg [15:0] checksum;
    reg [15:0] computed_checksum;
    reg [15:0] computed_checksum_next;
    reg [2:0] state;
    reg [2:0] state_next;
    reg [9:0] byte_count;
    
    // Pipeline registers for critical path optimization
    reg [7:0] rx_byte_pipe;
    reg packet_end_pipe;
    reg packet_end_valid_pipe;
    reg [15:0] checksum_pipe;
    
    // Handshake control signals
    wire rx_transfer;
    wire packet_start_transfer;
    wire packet_end_transfer;
    wire checksum_transfer;
    
    // State definitions
    localparam IDLE = 3'd0, HEADER = 3'd1, DATA = 3'd2, CHECKSUM_L = 3'd3, CHECKSUM_H = 3'd4;
    
    // Handshake transfer signals
    assign rx_transfer = rx_valid && rx_ready;
    assign packet_start_transfer = packet_start_valid && packet_start_ready;
    assign packet_end_transfer = packet_end_valid && packet_end_ready;
    assign checksum_transfer = checksum_valid && checksum_ready;
    
    // First pipeline stage - register inputs with handshaking
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            rx_byte_pipe <= 8'd0;
            packet_end_pipe <= 1'b0;
            packet_end_valid_pipe <= 1'b0;
        end else if (rx_transfer) begin
            rx_byte_pipe <= rx_byte;
            packet_end_pipe <= packet_end;
            packet_end_valid_pipe <= packet_end_valid;
        end
    end
    
    // Compute next checksum value in separate combinational block to reduce critical path
    always @(*) begin
        computed_checksum_next = computed_checksum + rx_byte_pipe;
        
        // Determine next state based on current state and inputs
        state_next = state;
        
        case (state)
            HEADER: begin
                if (byte_count < 13) begin
                    state_next = HEADER;
                end else begin
                    state_next = DATA;
                end
            end
            
            DATA: begin
                if (packet_end_pipe && packet_end_valid_pipe) begin
                    state_next = CHECKSUM_L;
                end else begin
                    state_next = DATA;
                end
            end
            
            CHECKSUM_L: begin
                state_next = CHECKSUM_H;
            end
            
            CHECKSUM_H: begin
                state_next = IDLE;
            end
            
            default: begin
                state_next = IDLE;
            end
        endcase
        
        if (packet_end_pipe && packet_end_valid_pipe && state != CHECKSUM_H) begin
            state_next = IDLE;
        end
    end
    
    // Ready signals management
    always @(*) begin
        // Default values
        rx_ready = 1'b0;
        packet_start_ready = 1'b0;
        packet_end_ready = 1'b0;
        
        case (state)
            IDLE: begin
                // In IDLE, ready to accept packet_start
                packet_start_ready = 1'b1;
                rx_ready = 1'b0;
                packet_end_ready = 1'b0;
            end
            
            HEADER, DATA: begin
                // During data processing, ready to accept bytes and end signal
                rx_ready = 1'b1;
                packet_end_ready = 1'b1;
                packet_start_ready = 1'b0;
            end
            
            CHECKSUM_L, CHECKSUM_H: begin
                // During checksum verification, still ready to accept bytes
                rx_ready = 1'b1;
                packet_end_ready = 1'b0;
                packet_start_ready = 1'b0;
            end
        endcase
    end
    
    // Second pipeline stage - update state and checksum
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_count <= 10'd0;
            checksum <= 16'd0;
            computed_checksum <= 16'd0;
            checksum_ok <= 1'b0;
            checksum_valid <= 1'b0;
            checksum_pipe <= 16'd0;
        end else begin
            if (packet_start_transfer) begin
                state <= HEADER;
                byte_count <= 10'd0;
                computed_checksum <= 16'd0;
                checksum_ok <= 1'b0;
                checksum_valid <= 1'b0;
            end else if (rx_transfer) begin
                state <= state_next;
                
                case (state)
                    HEADER: begin
                        if (byte_count < 13) begin
                            byte_count <= byte_count + 1'b1;
                        end else begin
                            byte_count <= 10'd0;
                        end
                    end
                    
                    DATA: begin
                        // Use pipelined checksum calculation
                        computed_checksum <= computed_checksum_next;
                    end
                    
                    CHECKSUM_L: begin
                        checksum[7:0] <= rx_byte_pipe;
                        checksum_pipe <= computed_checksum;
                    end
                    
                    CHECKSUM_H: begin
                        checksum[15:8] <= rx_byte_pipe;
                        checksum_valid <= 1'b1;
                        // Calculate checksum_ok with pre-registered values to reduce timing path
                        checksum_ok <= (checksum_pipe == {rx_byte_pipe, checksum[7:0]});
                    end
                endcase
            end
            
            if (packet_end_transfer && state != CHECKSUM_H) begin
                state <= IDLE;
                checksum_valid <= 1'b0;
            end
            
            // Clear checksum_valid when transfer completes
            if (checksum_transfer) begin
                checksum_valid <= 1'b0;
            end
        end
    end
endmodule