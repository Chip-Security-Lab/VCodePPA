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
    // State encoding
    localparam IDLE = 3'd0;
    localparam ARBITRATION = 3'd1;
    localparam DATA = 3'd2;
    localparam CRC = 3'd3;
    localparam ACK = 3'd4;

    // State registers
    reg [2:0] current_state;
    reg [2:0] next_state;

    // Data path registers
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [3:0] bit_counter; // Assuming max DATA_WIDTH is up to 15 bits for a 4-bit counter

    // Buffered signals for high fanout
    // These registers buffer the outputs of current_state and bit_counter
    // to reduce their fanout load on the clock path and improve timing.
    reg [2:0] current_state_buf;
    reg [3:0] bit_counter_buf;

    //==========================================================================
    // State Register Block
    // Updates the current state on clock edge or reset.
    // This block remains unchanged as it's the source of the state signal.
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    //==========================================================================
    // Buffered State and Counter Registers
    // Registers the outputs of current_state and bit_counter for fanout reduction.
    // Downstream logic will use these buffered versions, introducing one cycle latency.
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_buf <= IDLE; // Reset to initial state
        end else begin
            current_state_buf <= current_state; // Buffer current state
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter_buf <= 4'd0; // Reset to initial value
        end else begin
            bit_counter_buf <= bit_counter; // Buffer bit counter
        end
    end

    //==========================================================================
    // Next State Logic Block
    // Determines the next state based on buffered current state and inputs (combinational).
    // Uses buffered state and buffered counter.
    //==========================================================================
    always @(*) begin
        // Default: stay in current state (based on buffered state)
        next_state = current_state_buf;

        case(current_state_buf) // Use buffered state
            IDLE: begin
                if (tx_valid) begin
                    next_state = ARBITRATION; // Start transmission process
                end else begin
                    next_state = IDLE; // Stay idle if no TX request
                end
            end
            ARBITRATION: begin
                // Simplified arbitration logic: assume we win if can_rx is high (recessive)
                // In a real CAN, this would involve comparing transmitted vs received bits
                if (can_rx) begin // Simplified: Assume we lose arbitration if bus is recessive when we drive dominant
                    next_state = IDLE; // Abort transmission
                end else begin
                    next_state = DATA; // Assume we won and proceed to data transmission
                end
            end
            DATA: begin
                // Use buffered counter for state transition condition
                if (bit_counter_buf == 0) begin
                    next_state = CRC; // All data bits sent (condition based on buffered counter)
                end else begin
                    next_state = DATA; // Continue sending data bits
                end
            end
            CRC: begin
                next_state = ACK; // CRC sent, proceed to ACK slot
            end
            ACK: begin
                next_state = IDLE; // Frame complete, return to idle
            end
            default: begin
                next_state = IDLE; // Should not happen, but reset to IDLE
            end
        endcase
    end

    //==========================================================================
    // Transmit Data Path Block
    // Handles the transmit shift register and bit counter.
    // Uses buffered state and buffered counter for conditions.
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            bit_counter <= 4'd0;
        end else begin
            case(current_state_buf) // Use buffered state
                IDLE: begin
                    if (tx_valid) begin // Load data and counter when starting TX from IDLE (based on buffered state)
                        tx_shift_reg <= tx_data;
                        bit_counter <= DATA_WIDTH;
                    end
                end
                DATA: begin
                    // Use buffered counter for shift/decrement condition
                    if (bit_counter_buf > 0) begin // Shift data and decrement counter during DATA phase (based on buffered counter)
                        tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0}; // Shift out MSB first (adjust if LSB first)
                        bit_counter <= bit_counter - 1; // Update original counter
                    end
                end
                // In other states, these registers hold their values
                default: begin
                    // Implicit latching - registers retain value
                end
            endcase
        end
    end

    //==========================================================================
    // Transmit Control Signal Block
    // Manages the tx_ready signal.
    // Uses buffered state.
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_ready <= 1'b1; // Ready by default
        end else begin
            case(current_state_buf) // Use buffered state
                IDLE: begin
                    if (tx_valid) begin // Not ready when TX request is asserted in IDLE (based on buffered state)
                        tx_ready <= 1'b0;
                    end
                end
                ACK: begin // Ready again after ACK (end of frame) (based on buffered state)
                    tx_ready <= 1'b1;
                end
                // In other states, tx_ready holds its value (should be 0 during TX)
                default: begin
                    // Implicit latching - register retains value
                end
            endcase
        end
    end

    //==========================================================================
    // Receive Control and Data Block
    // Manages the rx_valid and rx_data signals.
    // Uses buffered state.
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0;
            rx_data <= {DATA_WIDTH{1'b0}};
        end else begin
            case(current_state_buf) // Use buffered state
                 IDLE: begin
                    // Original behavior: set rx_valid = 0 in IDLE only if tx_valid is high.
                    // This seems unusual, but maintained for functional equivalence based on buffered state.
                    if (tx_valid) begin
                         rx_valid <= 1'b0;
                    end else begin
                         // Implicit latching - rx_valid retains value if tx_valid is low in IDLE
                    end
                end
                ACK: begin // Data received and valid at the end of the frame (simplified) (based on buffered state)
                    rx_valid <= 1'b1;
                    rx_data <= tx_data; // Simplified: In a real CAN controller, this would be data received from can_rx
                end
                default: begin
                    // In other states, these registers hold their values
                    // Implicit latching - registers retain value
                end
            endcase
        end
    end

    //==========================================================================
    // Transmit Output Block
    // Controls the physical can_tx line.
    // Uses buffered state.
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1; // Recessive state by default
        end else begin
            case(current_state_buf) // Use buffered state
                ARBITRATION: can_tx <= 1'b0; // Dominant during SOF (simplified)
                DATA: can_tx <= tx_shift_reg[DATA_WIDTH-1]; // Transmit data bits (MSB first)
                default: can_tx <= 1'b1; // Recessive in other states (IDLE, CRC, ACK)
            endcase
        end
    end

endmodule