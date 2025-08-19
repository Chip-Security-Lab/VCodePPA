//SystemVerilog
module CAN_Transmitter_Config #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter BIT_TIME = 100
)(
    input clk,
    input rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data_in,
    input transmit_en,
    output reg can_tx,
    output reg tx_complete
);
    localparam TOTAL_BITS = ADDR_WIDTH + DATA_WIDTH + 3;
    reg [7:0] bit_timer;
    reg [7:0] bit_counter;
    reg [TOTAL_BITS-1:0] shift_reg;

    // Wires for incrementer outputs
    wire [7:0] next_bit_timer;
    wire [7:0] next_bit_counter;

    // Ripple-carry incrementer logic for bit_timer + 1
    wire [7:0] timer_carries;
    assign timer_carries[0] = 1'b1;
    assign next_bit_timer[0] = bit_timer[0] ^ timer_carries[0];
    genvar k;
    generate
      for (k = 1; k < 8; k = k + 1) begin : timer_inc_gen
        assign timer_carries[k] = bit_timer[k-1] & timer_carries[k-1];
        assign next_bit_timer[k] = bit_timer[k] ^ timer_carries[k];
      end
    endgenerate

    // Ripple-carry incrementer logic for bit_counter + 1
    wire [7:0] counter_carries;
    assign counter_carries[0] = 1'b1;
    assign next_bit_counter[0] = bit_counter[0] ^ counter_carries[0];
    generate
      for (k = 1; k < 8; k = k + 1) begin : counter_inc_gen
        assign counter_carries[k] = bit_counter[k-1] & counter_carries[k-1];
        assign next_bit_counter[k] = bit_counter[k] ^ counter_carries[k];
      end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer <= 8'd0;
            bit_counter <= 8'd0;
            shift_reg <= {TOTAL_BITS{1'b0}}; // Original reset value
            can_tx <= 1'b0; // Original reset value
            tx_complete <= 1'b0;
        end else begin
            tx_complete <= 1'b0; // default

            if (bit_timer < BIT_TIME-1) begin
                bit_timer <= next_bit_timer; // Use incrementer output
            end else begin // End of a bit time
                bit_timer <= 8'd0;

                if (bit_counter < TOTAL_BITS) begin // Transmitting bits
                    can_tx <= shift_reg[TOTAL_BITS-1]; // Output current bit
                    shift_reg <= {shift_reg[TOTAL_BITS-2:0], 1'b0}; // Shift left, fill with 0 (Original behavior)
                    bit_counter <= next_bit_counter; // Use incrementer output
                end else begin // Transmission complete or idle
                    tx_complete <= 1'b1; // Signal completion
                    bit_counter <= 8'd0; // Reset counter
                    can_tx <= 1'b1; // Idle state is high (Original behavior)
                    if (transmit_en) begin // Start new transmission
                        // Load shift register. Assuming 3'b101 is the desired prefix.
                        shift_reg <= {3'b101, addr, data_in};
                    end else begin
                         // Stay in idle state if transmit_en is not asserted
                         shift_reg <= {TOTAL_BITS{1'b1}}; // Idle state shift register all 1s (Original behavior)
                         // can_tx already set high above
                    end
                end
            end
        end
    end

endmodule