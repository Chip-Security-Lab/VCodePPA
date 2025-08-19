//SystemVerilog
// Top level module orchestrating CAN RX and TX submodules
module CAN_Controller_Top #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    output can_tx,
    input [DATA_WIDTH-1:0] tx_data,
    input tx_data_valid,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg tx_irq,
    output reg rx_irq,
    output reg error_irq // Placeholder, no error logic in original
);

    // State machine for the top-level controller
    // One-cold encoding: 3 states require 3 bits
    localparam [2:0]
        STATE_IDLE = 3'b011, // Bit 2 is 0
        STATE_RX   = 3'b101, // Bit 1 is 0
        STATE_TX   = 3'b110; // Bit 0 is 0

    reg [2:0] state, next_state;

    // Signals connecting to submodules
    wire start_rx_s;
    wire start_tx_s;
    wire [DATA_WIDTH-1:0] rx_data_s;
    wire rx_done_s;
    wire rx_active_s; // Not used by top, but useful for debug/future
    wire can_tx_s;
    wire tx_done_s;
    wire tx_busy_s; // Not used by top, but useful for debug/future

    // Instantiate Receiver Submodule
    can_rx_core #(
        .DATA_WIDTH(DATA_WIDTH)
    ) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_rx_i(start_rx_s),
        .can_rx_i(can_rx),
        .rx_data_o(rx_data_s),
        .rx_done_o(rx_done_s),
        .rx_active_o(rx_active_s)
    );

    // Instantiate Transmitter Submodule
    can_tx_core #(
        .DATA_WIDTH(DATA_WIDTH)
    ) tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start_tx_i(start_tx_s),
        .tx_data_i(tx_data),
        .can_tx_o(can_tx_s),
        .tx_done_o(tx_done_s),
        .tx_busy_o(tx_busy_s)
    );

    // Connect submodule output to top output
    assign can_tx = can_tx_s;

    // Top-level state machine logic
    always @(*) begin
        next_state = state; // Default: stay in current state

        // Use full state encoding in case statement
        case (state)
            STATE_IDLE: begin // 3'b011
                if (tx_data_valid) begin // TX request has priority
                    next_state = STATE_TX;
                end else if (can_rx == 1'b0) begin // Detect start bit
                    next_state = STATE_RX;
                end
            end
            STATE_RX: begin // 3'b101
                if (tx_data_valid) begin // TX request interrupts RX
                    next_state = STATE_TX;
                end else if (rx_done_s) begin
                    next_state = STATE_IDLE;
                end
            end
            STATE_TX: begin // 3'b110
                if (tx_done_s) begin
                    next_state = STATE_IDLE;
                end
            end
            default: begin // Handle invalid states (should not happen with proper FSM)
                next_state = STATE_IDLE;
            end
        endcase
    end

    // State and output registers update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= STATE_IDLE; // Reset to IDLE (3'b011)
            tx_irq      <= 1'b0;
            rx_irq      <= 1'b0;
            error_irq   <= 1'b0;
            rx_data     <= {DATA_WIDTH{1'b0}};
        end else begin
            state <= next_state;

            // Interrupt generation (pulse high for one cycle)
            // Compare against one-cold states
            tx_irq <= (state == STATE_TX && next_state == STATE_IDLE);
            // rx_irq generated only if RX finished AND was not interrupted by TX
            rx_irq <= (state == STATE_RX && next_state == STATE_IDLE && !tx_data_valid);

            // Update rx_data register when reception is done
            if (rx_done_s) begin
                rx_data <= rx_data_s;
            end

            // Error IRQ (not implemented in original, keep low)
            error_irq <= 1'b0;
        end
    end

    // Control signals for submodules based on top state
    // Compare against one-cold states
    assign start_rx_s = (state == STATE_RX); // Tell RX core to be active
    assign start_tx_s = (state == STATE_TX); // Tell TX core to be active

endmodule


// CAN Receiver Core Submodule
// Handles bit-level reception, data assembly, and completion detection.
module can_rx_core #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input start_rx_i,   // Level signal from top: start/continue receiving
    input can_rx_i,
    output reg [DATA_WIDTH-1:0] rx_data_o,
    output reg rx_done_o,      // Pulse high for one cycle when reception finishes
    output reg rx_active_o     // Level high when receiving
);

    // State machine for RX core
    // One-cold encoding: 3 states require 3 bits
    localparam [2:0]
        RX_IDLE       = 3'b011, // Bit 2 is 0
        RX_ACTIVE     = 3'b101, // Bit 1 is 0
        RX_DONE_PULSE = 3'b110; // Bit 0 is 0

    reg [2:0] rx_state, next_rx_state;
    reg [DATA_WIDTH-1:0] rx_shift_reg;
    reg [3:0] rx_bit_cnt; // Assuming DATA_WIDTH <= 16 for 4 bits

    // RX core state transition logic
    always @(*) begin
        next_rx_state = rx_state; // Default: stay in current state
        rx_done_o = 1'b0;         // Default: done pulse low

        // Use full state encoding in case statement
        case (rx_state)
            RX_IDLE: begin // 3'b011
                if (start_rx_i) begin // Top module signals to start/continue RX
                    next_rx_state = RX_ACTIVE;
                end
            end
            RX_ACTIVE: begin // 3'b101
                if (rx_bit_cnt == DATA_WIDTH - 1) begin
                    next_rx_state = RX_DONE_PULSE;
                end
                // If start_rx_i goes low, it means top module was interrupted (e.g., by TX)
                // Original code didn't handle this cleanly, but let's reset if interrupted.
                // This might cause partial data loss but matches original's TX priority.
                if (!start_rx_i) begin
                    next_rx_state = RX_IDLE;
                end
            end
            RX_DONE_PULSE: begin // 3'b110
                next_rx_state = RX_IDLE; // Return to idle after one cycle pulse
                rx_done_o = 1'b1;       // Assert done pulse
            end
            default: begin // Handle invalid states
                next_rx_state = RX_IDLE;
            end
        endcase
    end

    // RX core state and data/counter update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state     <= RX_IDLE; // Reset to IDLE (3'b011)
            rx_shift_reg <= {DATA_WIDTH{1'b0}};
            rx_bit_cnt   <= 4'b0;
            rx_data_o    <= {DATA_WIDTH{1'b0}}; // Reset output data
            rx_active_o  <= 1'b0;
        end else begin
            rx_state <= next_rx_state;

            // Update rx_active_o level
            // Compare against one-cold states
            rx_active_o <= (next_rx_state == RX_ACTIVE || next_rx_state == RX_DONE_PULSE); // Active until done pulse is sent

            // Use full state encoding in case statement
            case (rx_state)
                RX_IDLE: begin // 3'b011
                    // Reset counter and shift register when starting
                    // Compare against one-cold state
                    if (next_rx_state == RX_ACTIVE) begin
                        rx_bit_cnt   <= 4'b0;
                        rx_shift_reg <= {DATA_WIDTH{1'b0}};
                    end
                end
                RX_ACTIVE: begin // 3'b101
                    // Shift in new bit and increment counter
                    rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], can_rx_i};
                    rx_bit_cnt   <= rx_bit_cnt + 1;
                end
                RX_DONE_PULSE: begin // 3'b110
                    // Latch final data and reset counter
                    rx_data_o    <= rx_shift_reg;
                    rx_bit_cnt   <= 4'b0; // Reset counter for next reception
                end
            endcase

            // If interrupted by top module (start_rx_i goes low while active), reset
            // Compare against one-cold states
            if (rx_state == RX_ACTIVE && next_rx_state == RX_IDLE) begin
                 rx_bit_cnt   <= 4'b0;
                 rx_shift_reg <= {DATA_WIDTH{1'b0}};
                 rx_data_o    <= {DATA_WIDTH{1'b0}};
            end
        end
    end

endmodule


// CAN Transmitter Core Submodule
// Handles data loading, bit-level transmission, and completion detection.
module can_tx_core #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input start_tx_i,   // Level signal from top: start/continue transmitting
    input [DATA_WIDTH-1:0] tx_data_i, // Data to transmit
    output reg can_tx_o,       // Output CAN bit
    output reg tx_done_o,      // Pulse high for one cycle when transmission finishes
    output reg tx_busy_o       // Level high when transmitting
);

    // State machine for TX core
    // One-cold encoding: 3 states require 3 bits
    localparam [2:0]
        TX_IDLE       = 3'b011, // Bit 2 is 0
        TX_ACTIVE     = 3'b101, // Bit 1 is 0
        TX_DONE_PULSE = 3'b110; // Bit 0 is 0

    reg [2:0] tx_state, next_tx_state;
    reg [DATA_WIDTH-1:0] tx_shift_reg; // Shift register for transmission
    reg [3:0] tx_bit_cnt; // Assuming DATA_WIDTH <= 16 for 4 bits
    reg [DATA_WIDTH-1:0] tx_data_reg; // Register to hold data during transmission

    // TX core state transition logic
    always @(*) begin
        next_tx_state = tx_state; // Default: stay in current state
        tx_done_o = 1'b0;         // Default: done pulse low

        // Use full state encoding in case statement
        case (tx_state)
            TX_IDLE: begin // 3'b011
                if (start_tx_i) begin // Top module signals to start TX
                    next_tx_state = TX_ACTIVE;
                end
            end
            TX_ACTIVE: begin // 3'b101
                if (tx_bit_cnt == DATA_WIDTH - 1) begin
                    next_tx_state = TX_DONE_PULSE;
                end
                // TX is not interruptible by RX in the original code's logic,
                // so no state change based on !start_tx_i here unless reset.
            end
            TX_DONE_PULSE: begin // 3'b110
                next_tx_state = TX_IDLE; // Return to idle after one cycle pulse
                tx_done_o = 1'b1;       // Assert done pulse
            end
            default: begin // Handle invalid states
                next_tx_state = TX_IDLE;
            end
        endcase
    end

    // TX core state and data/counter update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state     <= TX_IDLE; // Reset to IDLE (3'b011)
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            tx_bit_cnt   <= 4'b0;
            can_tx_o     <= 1'b1; // CAN bus is recessive (high) when idle
            tx_busy_o    <= 1'b0;
            tx_data_reg  <= {DATA_WIDTH{1'b0}};
        end else begin
            tx_state <= next_tx_state;

            // Update tx_busy_o level
            // Compare against one-cold states
            tx_busy_o <= (next_tx_state == TX_ACTIVE || next_tx_state == TX_DONE_PULSE); // Busy until done pulse is sent

            // Use full state encoding in case statement
            case (tx_state)
                TX_IDLE: begin // 3'b011
                    can_tx_o <= 1'b1; // Keep bus high when idle
                    // Load data and reset counter when starting
                    // Compare against one-cold state
                    if (next_tx_state == TX_ACTIVE) begin
                        tx_data_reg  <= tx_data_i; // Latch data
                        tx_shift_reg <= tx_data_i; // Load shift register
                        tx_bit_cnt   <= 4'b0;      // Reset counter
                    end
                end
                TX_ACTIVE: begin // 3'b101
                    // Output MSB and shift left
                    can_tx_o     <= tx_shift_reg[DATA_WIDTH-1];
                    tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0}; // Shift left
                    tx_bit_cnt   <= tx_bit_cnt + 1;                    // Increment counter
                end
                TX_DONE_PULSE: begin // 3'b110
                    can_tx_o     <= 1'b1; // Return bus to recessive (high)
                    tx_bit_cnt   <= 4'b0; // Reset counter for next transmission
                end
            endcase
        end
    end

endmodule