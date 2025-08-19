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
    // Total bits to transmit: 3 header bits + address + data
    // Assuming 3 header bits are part of the data stream being shifted out.
    localparam TOTAL_BITS = ADDR_WIDTH + DATA_WIDTH + 3;

    // Internal registers
    // bit_timer counts clock cycles within one bit time period
    reg [7:0] bit_timer;
    // bit_counter counts the number of bits transmitted
    reg [7:0] bit_counter; // Assuming TOTAL_BITS <= 256
    // shift_reg holds the data to be transmitted
    reg [TOTAL_BITS-1:0] shift_reg;

    // Derived signal indicating the end of a bit time period
    wire tick = (bit_timer == BIT_TIME - 1);

    // Derived signals based on bit_counter state
    wire transmission_in_progress = (bit_counter < TOTAL_BITS);
    wire transmission_complete_cycle = (bit_counter == TOTAL_BITS);

    // Wires for parallel prefix adder outputs
    wire [7:0] bit_timer_plus_1;
    wire [7:0] bit_counter_plus_1;

    // Parallel Prefix Adder logic for bit_timer + 1
    // Sum[i] = X[i] ^ CarryIn[i]
    // CarryIn[i] = &X[i-1:0] for i > 0
    // CarryIn[0] = 0 (for +1 operation with cin=0)
    assign bit_timer_plus_1[0] = ~bit_timer[0]; // X[0] ^ 1

    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : timer_ppa_gen
            wire carry_in_i = &bit_timer[i-1:0];
            assign bit_timer_plus_1[i] = bit_timer[i] ^ carry_in_i;
        end
    endgenerate

    // Parallel Prefix Adder logic for bit_counter + 1
    // Sum[i] = X[i] ^ CarryIn[i]
    // CarryIn[i] = &X[i-1:0] for i > 0
    // CarryIn[0] = 0 (for +1 operation with cin=0)
    assign bit_counter_plus_1[0] = ~bit_counter[0]; // X[0] ^ 1

    genvar j;
    generate
        for (j = 1; j < 8; j = j + 1) begin : counter_ppa_gen
            wire carry_in_j = &bit_counter[j-1:0];
            assign bit_counter_plus_1[j] = bit_counter[j] ^ carry_in_j;
        end
    endgenerate


    // Always block for bit_timer logic
    // Increments every clock cycle, resets when a bit time is complete
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer <= 0;
        end else begin
            if (tick) begin
                bit_timer <= 0; // Reset timer at the end of a bit time
            end else begin
                bit_timer <= bit_timer_plus_1; // Increment timer using PPA output
            end
        end
    end

    // Always block for bit_counter logic
    // Increments when a bit time is complete and transmission is ongoing
    // Resets when transmission is complete
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
        end else begin
            if (tick) begin
                if (transmission_in_progress) begin // Still transmitting bits
                    bit_counter <= bit_counter_plus_1; // Move to next bit using PPA output
                end else begin // Finished transmitting all bits (bit_counter == TOTAL_BITS)
                    bit_counter <= 0; // Reset counter for next transmission
                end
            end
            // else bit_counter holds its value
        end
    end

    // Always block for shift_reg logic
    // Shifts data out when a bit time is complete and transmission is ongoing
    // Loads new data when transmission is complete and transmit_en is high
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
        end else begin
            if (tick) begin
                if (transmission_in_progress) begin // Shift out the next bit
                    shift_reg <= {shift_reg[TOTAL_BITS-2:0], 1'b0};
                end else begin // Finished transmitting all bits (bit_counter == TOTAL_BITS)
                    // Load new data if transmit_en is high, otherwise hold value
                    if (transmit_en) begin
                         // Load pattern {3'b101, addr, data_in} as per original code
                         shift_reg <= {3'b101, addr, data_in};
                    end
                end
            end
            // else shift_reg holds its value
        end
    end

    // Always block for can_tx output logic
    // can_tx outputs the current bit from the shift register when a bit time is complete and transmission is ongoing
    // Holds its value otherwise (including when transmission is complete or timer is running)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 0; // Default state (assuming dominant low or reset value)
        end else begin
            if (tick && transmission_in_progress) begin
                can_tx <= shift_reg[TOTAL_BITS-1]; // Output the current bit
            end
            // else can_tx holds its value
        end
    end

    // Always block for tx_complete output logic
    // tx_complete signals completion for one cycle when the last bit time finishes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_complete <= 0;
        end else begin
            // Signal completion when tick is high and bit_counter is at the final count (TOTAL_BITS)
            if (tick && transmission_complete_cycle) begin
                tx_complete <= 1; // Set high for one cycle
            end else begin
                tx_complete <= 0; // Clear the signal otherwise
            end
        end
    end

endmodule