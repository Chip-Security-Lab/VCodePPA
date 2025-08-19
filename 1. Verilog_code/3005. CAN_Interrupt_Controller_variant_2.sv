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

    // Local parameter for the comparison value
    // Assumes DATA_WIDTH-1 fits in 4 bits, as bit_cnt is 4 bits
    localparam [3:0] CNT_MAX_VAL = DATA_WIDTH - 1;

    reg [2:0] state;
    reg [DATA_WIDTH-1:0] tx_shift;
    reg [3:0] bit_cnt;
    reg rx_active;

    // Direct comparison wire
    wire cnt_equals_max = (bit_cnt == CNT_MAX_VAL);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            tx_irq <= 0;
            rx_irq <= 0;
            error_irq <= 0;
            bit_cnt <= 0;
            can_tx <= 1'b1;
            tx_shift <= 0;
            rx_data <= 0;
            rx_active <= 0;
        end else begin
            // Handle tx_data_valid as an overriding signal
            if (tx_data_valid) begin
                tx_shift <= tx_data;
                state <= 2;
                bit_cnt <= 0; // Initialize bit counter for TX
                tx_irq <= 0; // Clear TX interrupt flag
                // rx_active, rx_data, error_irq are not affected by starting TX
            end else begin // Process state machine logic only if not starting TX
                case(state)
                    0: begin // Idle state
                        // can_tx remains high in idle
                        if (can_rx == 1'b0) begin // Start of frame detected
                            state <= 1; // Go to RX state
                            rx_active <= 1;
                            bit_cnt <= 0; // Reset bit counter for RX
                            // tx_irq, rx_irq, error_irq remain unchanged unless set elsewhere
                        end
                    end
                    1: begin // RX state
                        // can_tx remains high in RX
                        // Sample can_rx on the rising edge
                        rx_data <= {rx_data[DATA_WIDTH-2:0], can_rx};
                        bit_cnt <= bit_cnt + 1; // Increment bit counter

                        // Check if all bits received using direct comparison
                        if (cnt_equals_max) begin
                            rx_irq <= 1; // Set RX interrupt
                            state <= 0; // Return to Idle
                            rx_active <= 0;
                        end
                    end
                    2: begin // TX state
                        // Output the current bit and shift
                        can_tx <= tx_shift[DATA_WIDTH-1];
                        tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0}; // Shift left, pad with 0

                        // Check if all bits transmitted using direct comparison
                        if (cnt_equals_max) begin // Check current bit_cnt value
                            tx_irq <= 1; // Set TX interrupt
                            state <= 0; // Return to Idle
                            // rx_active, rx_data, error_irq remain unchanged
                        end else begin
                            bit_cnt <= bit_cnt + 1; // Increment bit counter for the next bit
                        end
                    end
                    default: begin // Should not happen, return to idle
                        state <= 0;
                        // All other signals hold their value or are reset by rst_n
                    end
                endcase
            end
        end
    end
endmodule