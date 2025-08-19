//SystemVerilog
module CAN_Controller_Sync #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4 // ADDR_WIDTH is not used in this simplified module
)(
    input clk,
    input rst_n,
    input can_rx,         // CAN Receive input
    output reg can_tx,    // CAN Transmit output (open-drain, 0=Dominant, 1=Recessive)
    input [DATA_WIDTH-1:0] tx_data, // Data to transmit
    output reg [DATA_WIDTH-1:0] rx_data, // Received data (simplified in this module)
    input tx_valid,       // Pulse to start transmission
    output reg tx_ready,  // Ready to accept new tx_data
    output reg rx_valid   // Indicates rx_data is valid (simplified)
);

    // State Encoding (Binary Encoding)
    localparam IDLE        = 3'b000; // Controller is idle, ready to transmit or receive
    localparam ARBITRATION = 3'b001; // Transmitting arbitration field (simplified)
    localparam DATA        = 3'b010; // Transmitting data field (simplified)
    localparam CRC         = 3'b011; // Transmitting CRC field (simplified)
    localparam ACK         = 3'b100; // Handling ACK slot (simplified)

    // FSM State Registers
    reg [2:0] current_state;
    reg [2:0] next_state;

    // Transmit Shift Register and Bit Counter
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [3:0] bit_counter; // Counter for data bits

    //------------------------------------------------------------------------
    // State Register
    // Updates the current state on clock edge or reset
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    //------------------------------------------------------------------------
    // Next State Logic (Combinational) - Flattened if-else structure
    // Determines the next state based on current state and inputs
    //------------------------------------------------------------------------
    always @(*) begin
        // Default assignment
        next_state = current_state;

        // Flattened state transitions
        if (current_state == IDLE && tx_valid) begin
            next_state = ARBITRATION;
        end else if (current_state == IDLE && !tx_valid) begin
            next_state = IDLE;
        end else if (current_state == ARBITRATION && can_rx) begin
            next_state = IDLE; // Loss of arbitration
        end else if (current_state == ARBITRATION && !can_rx) begin
            next_state = DATA; // Arbitration won
        end else if (current_state == DATA && bit_counter == 0) begin
            next_state = CRC; // All data bits sent
        end else if (current_state == DATA && bit_counter != 0) begin
            next_state = DATA; // Still sending data bits
        end else if (current_state == CRC) begin
            next_state = ACK; // CRC sent
        end else if (current_state == ACK) begin
            next_state = IDLE; // ACK handled, return to idle
        end else begin
            // Should not reach here, but as a fallback, go to IDLE.
            next_state = IDLE;
        end
    end

    //------------------------------------------------------------------------
    // Transmit Data Shift Register and Counter Logic (Sequential) - Flattened
    // Loads data when transmission starts and shifts/counts during DATA state.
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            bit_counter <= 4'd0;
        end else begin
            // Flattened logic
            if (current_state == IDLE && tx_valid) begin
                // If tx_valid is high, load the data and initialize the counter
                tx_shift_reg <= tx_data;
                bit_counter <= DATA_WIDTH; // Start counter for DATA_WIDTH bits
            end else if (current_state == DATA && bit_counter > 0) begin
                // While in DATA state and bits remain, shift the register and decrement counter
                tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0}; // Shift left, MSB first
                bit_counter <= bit_counter - 1;
            end
            // In other states (ARBITRATION, CRC, ACK, default), registers hold their values.
        end
    end

    //------------------------------------------------------------------------
    // Transmit Ready Signal Logic (Sequential) - Flattened
    // Controls the tx_ready output based on the FSM state.
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_ready <= 1'b1; // Ready to accept data on reset
        end else begin
            // Flattened logic
            if (current_state == IDLE && tx_valid) begin
                // If tx_valid is asserted, controller becomes busy, tx_ready goes low
                tx_ready <= 1'b0; // Not ready while busy
            end else if (current_state == IDLE && !tx_valid) begin
                 tx_ready <= 1'b1; // Ready if staying in IDLE
            end else if (current_state == ACK) begin
                // Transmission cycle is finished (simplified), become ready again
                tx_ready <= 1'b1;
            end else begin // Remain not ready during ARBITRATION, DATA, CRC, default
                tx_ready <= 1'b0; // Hold low during transmission
            end
        end
    end

    //------------------------------------------------------------------------
    // Receive Data and Valid Signal Logic (Sequential)
    // Handles simplified reception. In this model, it just mirrors tx_data
    // and asserts rx_valid in the ACK state. No complex nested structure to flatten.
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0; // Not valid on reset
            rx_data <= {DATA_WIDTH{1'b0}}; // Reset received data
        end else begin
            // rx_valid is asserted only in the ACK state (simplified)
            rx_valid <= (current_state == ACK);

            // rx_data is updated in the ACK state (simplified model)
            // In a real CAN controller, this would capture data from the bus.
            if (current_state == ACK) begin
                rx_data <= tx_data; // Simplified: just pass tx_data
            end
            // In other states, rx_data holds its previous value
        end
    end

    //------------------------------------------------------------------------
    // CAN Bus Transmit Output Logic (Sequential) - Flattened
    // Drives the can_tx pin based on the current state and transmit data.
    // CAN uses open-drain, 0 (Dominant) overrides 1 (Recessive).
    // Idle/Recessive state is high (1).
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1; // Default to recessive (idle)
        end else begin
            // Flattened logic
            if (current_state == ARBITRATION) begin
                // Transmit dominant start bit (simplified)
                can_tx <= 1'b0;
            end else if (current_state == DATA) begin
                // Transmit the current bit from the shift register (MSB first)
                can_tx <= tx_shift_reg[DATA_WIDTH-1];
            end else begin // In IDLE, CRC, ACK, default states, drive recessive
                can_tx <= 1'b1;
            end
        end
    end

endmodule