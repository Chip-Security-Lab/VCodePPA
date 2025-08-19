//SystemVerilog
module eth_checksum_verifier (
    input wire clock,
    input wire reset,
    input wire data_valid,
    input wire [7:0] rx_byte,
    input wire packet_start,
    input wire packet_end,
    output reg checksum_ok,
    output reg checksum_valid
);
    // State definitions
    localparam IDLE = 3'd0, HEADER = 3'd1, DATA = 3'd2, CHECKSUM_L = 3'd3, CHECKSUM_H = 3'd4;
    
    // Registered signals
    reg [15:0] checksum;
    reg [15:0] computed_checksum;
    reg [2:0] state;
    reg [2:0] state_buf1, state_buf2; // Buffered state signals
    reg [9:0] byte_count;
    
    // Buffered high fan-out signals
    reg [7:0] rx_byte_buf1, rx_byte_buf2; // Buffered rx_byte
    reg [15:0] checksum_buf1, checksum_buf2; // Buffered checksum
    reg idle_detect, idle_detect_buf; // IDLE state detection buffer
    
    // Distributed computation signals
    reg [7:0] data_path_a, data_path_b;
    
    // First-level buffer registers
    always @(posedge clock) begin
        rx_byte_buf1 <= rx_byte;
        rx_byte_buf2 <= rx_byte_buf1;
        checksum_buf1 <= checksum;
        checksum_buf2 <= checksum_buf1;
        state_buf1 <= state;
        state_buf2 <= state_buf1;
        idle_detect <= (state == IDLE);
        idle_detect_buf <= idle_detect;
    end
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            byte_count <= 10'd0;
            checksum <= 16'd0;
            computed_checksum <= 16'd0;
            checksum_ok <= 1'b0;
            checksum_valid <= 1'b0;
            data_path_a <= 8'd0;
            data_path_b <= 8'd0;
        end else begin
            if (packet_start) begin
                state <= HEADER;
                byte_count <= 10'd0;
                computed_checksum <= 16'd0;
                checksum_ok <= 1'b0;
                checksum_valid <= 1'b0;
            end else if (data_valid) begin
                case (state)
                    IDLE: begin
                        // Default idle state behavior
                    end
                    
                    HEADER: begin
                        if (byte_count < 13) begin
                            byte_count <= byte_count + 1'b1;
                        end else begin
                            state <= DATA;
                            byte_count <= 10'd0;
                        end
                    end
                    
                    DATA: begin
                        // Split computation path to reduce fan-out
                        data_path_a <= rx_byte_buf1;
                        data_path_b <= rx_byte_buf2;
                        // Use buffered signals for computation
                        computed_checksum <= computed_checksum + data_path_a;
                        
                        // Assume checksum is last 2 bytes of packet
                        if (packet_end) begin
                            state <= CHECKSUM_L;
                        end
                    end
                    
                    CHECKSUM_L: begin
                        checksum[7:0] <= rx_byte_buf1;
                        state <= CHECKSUM_H;
                    end
                    
                    CHECKSUM_H: begin
                        checksum[15:8] <= rx_byte_buf1;
                        checksum_valid <= 1'b1;
                        // Use buffered signals to reduce critical path
                        checksum_ok <= (computed_checksum == {rx_byte_buf1, checksum_buf1[7:0]});
                        state <= IDLE;
                    end
                    
                    default: state <= IDLE;
                endcase
            end
            
            if (packet_end && state_buf1 != CHECKSUM_H) begin
                state <= IDLE;
                checksum_valid <= 1'b0;
            end
        end
    end

endmodule