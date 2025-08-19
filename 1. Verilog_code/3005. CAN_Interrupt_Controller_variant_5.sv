//SystemVerilog
// Helper function for calculating logarithm base 2
function integer clog2;
    input integer value;
    begin
        value = value - 1;
        for (clog2 = 0; value > 0; clog2 = clog2 + 1) begin
            value = value >> 1;
        end
    end
endfunction

//------------------------------------------------------------------------------
// can_receiver_dp Module
// Handles data path for CAN reception: bit shifting and counting.
//------------------------------------------------------------------------------
module can_receiver_dp #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,          // Incoming CAN data bit
    input rx_enable,       // Enable reception data path (shifting and counting)
    input rx_load_en,      // Pulse to reset internal counter

    output [DATA_WIDTH-1:0] rx_data, // Received data word
    output [clog2(DATA_WIDTH)-1:0] rx_count // Current bit count
);

    reg [DATA_WIDTH-1:0] rx_shift_reg;
    reg [clog2(DATA_WIDTH)-1:0] bit_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg <= 0;
            bit_cnt <= 0;
        end else begin
            if (rx_load_en) begin
                // Reset counter on load enable pulse from top
                bit_cnt <= 0;
            end else if (rx_enable) begin
                // Shift in data and increment counter when enabled
                rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], can_rx};
                bit_cnt <= bit_cnt + 1;
            end
        end
    end

    assign rx_data = rx_shift_reg;
    assign rx_count = bit_cnt;

endmodule

//------------------------------------------------------------------------------
// can_transmitter_dp Module
// Handles data path for CAN transmission: data loading, bit shifting, counting,
// and outputting the current bit.
//------------------------------------------------------------------------------
module can_transmitter_dp #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] tx_data_in, // Data word to transmit
    input tx_enable,       // Enable transmission data path (shifting and counting)
    input tx_load_en,      // Pulse to load data and reset internal counter

    output can_tx_bit,     // Current bit to be transmitted on CAN bus
    output [clog2(DATA_WIDTH)-1:0] tx_count // Current bit count
);

    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [clog2(DATA_WIDTH)-1:0] bit_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= 0;
            bit_cnt <= 0;
        end else begin
            if (tx_load_en) begin
                // Load data and reset counter on load enable pulse from top
                tx_shift_reg <= tx_data_in;
                bit_cnt <= 0;
            end else if (tx_enable) begin
                // Shift out data and increment counter when enabled
                // Shift left to output MSB first
                tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                bit_cnt <= bit_cnt + 1;
            end
        end
    end

    assign can_tx_bit = tx_shift_reg[DATA_WIDTH-1]; // Output MSB
    assign tx_count = bit_cnt;

endmodule

//------------------------------------------------------------------------------
// CAN_Interrupt_Controller Module (Top Level)
// Manages overall CAN state transitions and orchestrates receiver and
// transmitter data paths. Generates interrupts.
//------------------------------------------------------------------------------
module CAN_Interrupt_Controller #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,          // Incoming CAN data line
    output reg can_tx,     // Outgoing CAN data line

    input [DATA_WIDTH-1:0] tx_data, // Data to be transmitted
    input tx_data_valid, // Pulse or level indicating new data available for TX

    output [DATA_WIDTH-1:0] rx_data, // Received data word
    output reg tx_irq,     // Transmit complete interrupt pulse
    output reg rx_irq,     // Receive complete interrupt pulse
    output reg error_irq   // Error interrupt (not implemented in original logic)
);

    // State definitions
    localparam S_IDLE      = 2'd0;
    localparam S_RECEIVE   = 2'd1;
    localparam S_TRANSMIT  = 2'd2;

    // Internal state register
    reg [1:0] state;

    // Control signals for data path submodules
    reg rx_enable;
    reg rx_load_en;
    reg tx_enable;
    reg tx_load_en;

    // Signals from data path submodules
    wire [DATA_WIDTH-1:0] rx_data_int;
    wire [clog2(DATA_WIDTH)-1:0] rx_count;
    wire can_tx_bit_int;
    wire [clog2(DATA_WIDTH)-1:0] tx_count;

    // State machine and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            state <= S_IDLE;
            rx_enable <= 0;
            rx_load_en <= 0;
            tx_enable <= 0;
            tx_load_en <= 0;
            tx_irq <= 0;
            rx_irq <= 0;
            error_irq <= 0;
            can_tx <= 1'b1; // CAN bus idle state is recessive (high)
        end else begin
            // Default next state and control signals
            state <= state; // Stay in current state by default
            rx_enable <= 0;
            rx_load_en <= 0;
            tx_enable <= 0;
            tx_load_en <= 0;
            tx_irq <= 0; // Interrupts are pulsed for one cycle
            rx_irq <= 0;
            error_irq <= 0; // No error logic in original code
            can_tx <= 1'b1; // Default CAN bus state (recessive)

            // State transitions based on original logic
            case(state)
                S_IDLE: begin
                    if (tx_data_valid) begin
                        // Start transmission if requested and idle
                        state <= S_TRANSMIT;
                        tx_load_en <= 1; // Pulse to load data and reset counter
                        tx_enable <= 1;  // Enable transmitter DP
                        // tx_irq remains 0
                    end else if (can_rx == 1'b0) begin
                        // Detect start bit (simplified logic from original) and start reception if idle
                        state <= S_RECEIVE;
                        rx_load_en <= 1; // Pulse to reset counter
                        rx_enable <= 1;  // Enable receiver DP
                        // rx_irq remains 0
                    end
                    // If neither condition met, state remains S_IDLE
                end

                S_RECEIVE: begin
                    rx_enable <= 1; // Keep receiver DP enabled

                    // Check if reception is complete
                    if (rx_count == DATA_WIDTH - 1) begin
                        state <= S_IDLE;    // Go back to idle state
                        rx_enable <= 0;     // Disable receiver DP
                        rx_irq <= 1;        // Pulse receive interrupt
                    end
                    // If reception not complete, state remains S_RECEIVE
                end

                S_TRANSMIT: begin
                    tx_enable <= 1; // Keep transmitter DP enabled
                    can_tx <= can_tx_bit_int; // Drive CAN bus with the bit from DP

                    // Check if transmission is complete
                    if (tx_count == DATA_WIDTH - 1) begin
                        state <= S_IDLE;    // Go back to idle state
                        tx_enable <= 0;     // Disable transmitter DP
                        tx_irq <= 1;        // Pulse transmit interrupt
                        can_tx <= 1'b1;     // Release CAN bus (return to recessive)
                    end
                    // If transmission not complete, state remains S_TRANSMIT
                end

                default: begin
                    // Should not reach here, return to idle
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // Assign output rx_data from the receiver data path module
    assign rx_data = rx_data_int;

    // Instantiate the data path submodules
    can_receiver_dp #(DATA_WIDTH) receiver_inst (
        .clk(clk),
        .rst_n(rst_n),
        .can_rx(can_rx),
        .rx_enable(rx_enable),
        .rx_load_en(rx_load_en),
        .rx_data(rx_data_int), // Connect internal wire
        .rx_count(rx_count)   // Connect internal wire
    );

    can_transmitter_dp #(DATA_WIDTH) transmitter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data_in(tx_data), // Connect input data
        .tx_enable(tx_enable),
        .tx_load_en(tx_load_en),
        .can_tx_bit(can_tx_bit_int), // Connect internal wire
        .tx_count(tx_count)   // Connect internal wire
    );

endmodule