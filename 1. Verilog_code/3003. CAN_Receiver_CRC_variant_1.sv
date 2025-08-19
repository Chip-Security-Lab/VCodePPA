//SystemVerilog
module CAN_Receiver_CRC #(
    parameter DATA_WIDTH = 8,
    parameter CRC_WIDTH = 15
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg crc_error,
    output reg frame_valid
);

    // Internal state registers
    reg [DATA_WIDTH-1:0] state_shift_reg;
    reg [CRC_WIDTH-1:0] state_crc_reg;
    reg [3:0] state_bit_cnt; // Counter width assuming DATA_WIDTH <= 16

    // Combinatorial signals for next state and output values (driven by always @(*))
    reg [DATA_WIDTH-1:0] next_shift_reg;
    reg [CRC_WIDTH-1:0] next_crc_reg;
    reg [3:0] next_bit_cnt;
    reg [DATA_WIDTH-1:0] next_rx_data_val;
    reg next_crc_error_val;
    reg next_frame_valid_val;

    // Intermediate combinatorial signals (driven by always @(*))
    reg [15:0] crc_poly_xor_val;
    reg [CRC_WIDTH:0] crc_shifted;
    reg [CRC_WIDTH:0] crc_xor_result;

    // State conditions derived from current state
    wire is_processing_bits = (state_bit_cnt < DATA_WIDTH);
    wire is_end_of_frame = (state_bit_cnt == DATA_WIDTH); // Counter goes from 0 to DATA_WIDTH

    // --- Combinatorial Logic Block ---
    // This block calculates the next state and output values based on current state and inputs
    always @(*) begin
        // Calculate intermediate values first

        // Equivalent of: assign crc_poly_xor_val = can_rx ? 16'h4599 : 16'h0000;
        if (can_rx) begin
            crc_poly_xor_val = 16'h4599;
        end else begin
            crc_poly_xor_val = 16'h0000;
        end

        // Equivalent of: wire [CRC_WIDTH:0] crc_shifted = {state_crc_reg, 1'b0};
        crc_shifted = {state_crc_reg, 1'b0};

        // Equivalent of: wire [CRC_WIDTH:0] crc_xor_result = crc_shifted ^ { { (CRC_WIDTH + 1 - 16){1'b0} }, crc_poly_xor_val };
        crc_xor_result = crc_shifted ^ { { (CRC_WIDTH + 1 - 16){1'b0} }, crc_poly_xor_val };

        // Assign next state values using if-else

        // Equivalent of: assign next_shift_reg = is_processing_bits ? {state_shift_reg[DATA_WIDTH-2:0], can_rx} : state_shift_reg;
        if (is_processing_bits) begin
            next_shift_reg = {state_shift_reg[DATA_WIDTH-2:0], can_rx};
        end else begin
            next_shift_reg = state_shift_reg; // Keep value when not processing
        end

        // Equivalent of: assign next_crc_reg = is_processing_bits ? crc_xor_result[CRC_WIDTH-1:0] : state_crc_reg;
        if (is_processing_bits) begin
            next_crc_reg = crc_xor_result[CRC_WIDTH-1:0];
        end else begin
            next_crc_reg = state_crc_reg; // Keep value when not processing
        end

        // Equivalent of: assign next_bit_cnt = is_processing_bits ? state_bit_cnt + 1 : 0;
        if (is_processing_bits) begin
            next_bit_cnt = state_bit_cnt + 1;
        end else begin
            next_bit_cnt = 0; // Reset counter
        end

        // Assign next output values (these were simple assigns from state registers)
        // Equivalent of: assign next_rx_data_val = state_shift_reg;
        next_rx_data_val = state_shift_reg;
        // Equivalent of: assign next_frame_valid_val = (state_crc_reg == {CRC_WIDTH{1'b0}});
        next_frame_valid_val = (state_crc_reg == {CRC_WIDTH{1'b0}});
        // Equivalent of: assign next_crc_error_val = (state_crc_reg != {CRC_WIDTH{1'b0}});
        next_crc_error_val = (state_crc_reg != {CRC_WIDTH{1'b0}});
    end

    // --- Sequential Logic Block (Internal State Registers) ---
    // This block updates the internal state registers on the clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_shift_reg <= {DATA_WIDTH{1'b0}};
            state_crc_reg <= {CRC_WIDTH{1'b0}};
            state_bit_cnt <= 0;
        end else begin
            state_shift_reg <= next_shift_reg; // Register next data value
            state_crc_reg <= next_crc_reg;     // Register next CRC value
            state_bit_cnt <= next_bit_cnt;     // Register next counter value
        end
    end

    // --- Sequential Logic Block (Output Registers) ---
    // This block updates the output registers on the clock edge, conditionally
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= {DATA_WIDTH{1'b0}};
            crc_error <= 1'b0;
            frame_valid <= 1'b0;
        end else begin
            // Outputs are updated only when the end-of-frame condition is met
            if (is_end_of_frame) begin
                 rx_data <= next_rx_data_val;       // Register received data
                 crc_error <= next_crc_error_val;   // Register CRC error status
                 frame_valid <= next_frame_valid_val; // Register frame valid status
            end
            // Otherwise, outputs retain their previous value
        end
    end

endmodule