//SystemVerilog
module CAN_Interrupt_Controller #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg can_tx,
    input [DATA_WIDTH-1:0] tx_data,
    input tx_data_valid,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg tx_irq,
    output reg rx_irq,
    output reg error_irq
);
    // Registers
    reg [2:0] state;
    reg [DATA_WIDTH-1:0] tx_shift;
    reg [3:0] bit_cnt;
    reg rx_active;
    // Registered buffer for the comparison result of bit_cnt
    // This adds a pipeline stage for the signal (bit_cnt == DATA_WIDTH-1)
    reg bit_cnt_eq_max_q;

    // Block 1: State Register Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
        end else begin
            // Handle tx_data_valid logic - higher priority override
            if (tx_data_valid) begin
                state <= 2; // Go to transmit state
            end else begin
                // State machine logic
                case(state)
                    0: begin // Idle state
                        if (can_rx == 1'b0) begin // Detect start bit (falling edge)
                            state <= 1; // Go to receive state
                        end
                    end
                    1: begin // Receiving data state
                        // Transition based on buffered comparison result (from previous cycle)
                        if (bit_cnt_eq_max_q) begin
                            state <= 0; // Return to idle after receiving DATA_WIDTH bits
                        end
                        // else stay in state 1
                    end
                    2: begin // Transmitting data state
                        // Transition based on buffered comparison result (from previous cycle)
                        if (bit_cnt_eq_max_q) begin
                            state <= 0; // Return to idle after transmitting DATA_WIDTH bits
                        end
                        // else stay in state 2
                    end
                    default: begin // Should not happen, return to idle
                        state <= 0;
                    end
                endcase
            end
        end
    end

    // Block 2: Bit Counter Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 0;
        end else begin
            // Reset bit_cnt on new transmission request
            if (tx_data_valid) begin
                bit_cnt <= 0; // Initialize bit counter for transmission
            end else begin
                // Update bit_cnt based on state
                case(state)
                    0: begin // Idle
                        if (can_rx == 1'b0) begin
                           bit_cnt <= 0; // Reset bit_cnt for new reception
                        end else begin
                           bit_cnt <= 0; // Stay 0 in idle
                        end
                    end
                    1: begin // Receiving data
                        bit_cnt <= bit_cnt + 1; // Increment bit counter
                    end
                    2: begin // Transmitting data
                        bit_cnt <= bit_cnt + 1; // Increment bit counter
                    end
                    default: begin
                        bit_cnt <= 0; // Reset in default state
                    end
                endcase
            end
        end
    end

    // Block 3: TX Shift Register and Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= 0;
            can_tx <= 1'b1; // CAN idle state is recessive (high)
        end else begin
            // Load data and prepare for transmission
            if (tx_data_valid) begin
                 tx_shift <= tx_data; // Load data to transmit
                 // can_tx is not set here, will be set by state 2 logic next cycle
            end else begin
                // Handle transmission in state 2
                case(state)
                    2: begin // Transmitting data
                        can_tx <= tx_shift[DATA_WIDTH-1]; // Output current bit
                        tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0}; // Shift data
                    end
                    default: begin
                        can_tx <= 1'b1; // Default to recessive in idle/receive
                    end
                endcase
            end
        end
    end

    // Block 4: RX Data Register and Active Flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 0;
            rx_active <= 0;
        end else begin
            // Deactivate reception if transmission starts
            if (tx_data_valid) begin
                rx_active <= 0;
                // Original code did not clear rx_data here, maintaining functional equivalence
            end else begin
                // Handle reception in state 1
                case(state)
                    0: begin // Idle
                        if (can_rx == 1'b0) begin // Detect start bit
                            rx_active <= 1; // Indicate active reception
                            rx_data <= 0; // Clear previous data
                        end
                        // else rx_active stays 0, rx_data retains value
                    end
                    1: begin // Receiving data
                        rx_data <= {rx_data[DATA_WIDTH-2:0], can_rx}; // Shift in new bit
                        // Deactivate reception flag when reception is complete (state transitions next cycle)
                        if (bit_cnt_eq_max_q) begin
                             rx_active <= 0;
                        end
                    end
                    default: begin
                        rx_active <= 0; // Not active in transmit or other states
                        // rx_data retains value
                    end
                endcase
            end
        end
    end

    // Block 5: IRQ Generation (Sticky behavior)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_irq <= 0;
            rx_irq <= 0;
            error_irq <= 0; // Error IRQ logic not present in original
        end else begin
            // TX IRQ: Asserted when transmission finishes, cleared by new transmission request or reset
            if (tx_data_valid) begin
                tx_irq <= 0; // Clear TX IRQ flag when starting new transmission
            end
            // Assert TX IRQ when transmission finishes (state is 2 and bit_cnt_eq_max_q is true)
            if (state == 2 && bit_cnt_eq_max_q) begin
                tx_irq <= 1; // Assert TX IRQ
            end
            // Else, tx_irq retains its value unless cleared by tx_data_valid

            // RX IRQ: Asserted when reception finishes, cleared by reset
            // Assert RX IRQ when reception finishes (state is 1 and bit_cnt_eq_max_q is true)
            if (state == 1 && bit_cnt_eq_max_q) begin
                rx_irq <= 1; // Assert RX IRQ
            end
            // Else, rx_irq retains its value

            // Error IRQ (not used in original)
            error_irq <= 0; // Always 0
        end
    end

    // Block 6: Comparison Buffer Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt_eq_max_q <= 0; // Reset the buffer
        end else begin
            // Update the registered buffer for the comparison result
            // The comparison result from the current cycle is registered for use in the next cycle
            bit_cnt_eq_max_q <= (bit_cnt == DATA_WIDTH-1);
        end
    end

endmodule