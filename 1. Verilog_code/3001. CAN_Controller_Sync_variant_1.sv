//SystemVerilog
module CAN_Controller_Sync #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg can_tx,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    input tx_valid,
    output reg tx_ready,
    output reg rx_valid
);
    // State encoding using Johnson code (5 states require 5 bits for a simple sequence)
    localparam IDLE        = 5'b00000; // 0
    localparam ARBITRATION = 5'b10000; // 1
    localparam DATA        = 5'b11000; // 2
    localparam CRC         = 5'b11100; // 3
    localparam ACK         = 5'b11110; // 4
    
    reg [4:0] current_state, next_state; // State register width increased to 5 bits
    
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [3:0] bit_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            tx_ready <= 1'b1;
            rx_valid <= 1'b0;
            rx_data <= {DATA_WIDTH{1'b0}};
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            bit_counter <= 4'd0;
        end else begin
            current_state <= next_state;
            case(current_state)
                IDLE: begin
                    if (tx_valid) begin
                        tx_shift_reg <= tx_data;
                        bit_counter <= DATA_WIDTH;
                        tx_ready <= 1'b0;
                        rx_valid <= 1'b0;
                    end
                end
                DATA: begin
                    if (bit_counter > 0) begin
                        tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                        bit_counter <= bit_counter - 1;
                    end
                end
                ACK: begin
                    // Set rx_valid in ACK state
                    rx_valid <= 1'b1;
                    rx_data <= tx_data; // Simplified example, should get from bus
                    tx_ready <= 1'b1;
                end
                default: begin
                    // Default case to avoid latches for state-dependent outputs
                end
            endcase
        end
    end
    
    always @(*) begin
        // Default: stay in current state
        next_state = current_state; 
        
        case(current_state)
            IDLE: begin
                if (tx_valid) begin
                    next_state = ARBITRATION;
                end else begin
                    next_state = IDLE;
                end
            end
            ARBITRATION: begin
                if (can_rx) begin
                    next_state = IDLE;
                end else begin
                    next_state = DATA;
                end
            end
            DATA: begin
                if (bit_counter == 0) begin
                    next_state = CRC;
                end else begin
                    next_state = DATA;
                end
            end
            CRC: begin
                next_state = ACK;
            end
            ACK: begin
                next_state = IDLE;
            end
            default: begin
                // Handle illegal states by transitioning to a safe state
                next_state = IDLE; 
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1;
        end else begin
            case(current_state)
                ARBITRATION: can_tx <= 1'b0;
                DATA: can_tx <= tx_shift_reg[DATA_WIDTH-1];
                default: can_tx <= 1'b1;
            endcase
        end
    end
endmodule