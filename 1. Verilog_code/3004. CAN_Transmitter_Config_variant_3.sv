//SystemVerilog
// SystemVerilog
// Top module for the refactored CAN Transmitter Config
module CAN_Transmitter_Config_Refactored #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter BIT_TIME = 100
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire transmit_en,
    output wire can_tx,
    output wire tx_complete
);

    // Calculate total bits based on original logic loading {3'b101, addr, data_in}
    localparam TOTAL_BITS = ADDR_WIDTH + DATA_WIDTH + 3;
    localparam COUNTER_WIDTH = $clog2(TOTAL_BITS + 1);

    // Internal signals connecting submodules
    wire bit_tick;
    wire load_en;
    wire shifting_active;
    reg transmit_en_buf; // Buffered transmit enable

    // Buffer the transmit_en signal to avoid high fanout and potential timing issues
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transmit_en_buf <= 1'b0;
        end else begin
            transmit_en_buf <= transmit_en;
        end
    end

    // Instantiate the bit timer module
    can_bit_timer #(
        .BIT_TIME(BIT_TIME)
    ) bit_timer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bit_tick(bit_tick)
    );

    // Instantiate the transmission controller module
    can_tx_controller #(
        .TOTAL_BITS(TOTAL_BITS),
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) tx_controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bit_tick(bit_tick),
        .transmit_en_buf(transmit_en_buf),
        .load_en(load_en),
        .tx_complete(tx_complete),
        .shifting_active(shifting_active)
    );

    // Instantiate the data serializer module
    can_data_serializer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TOTAL_BITS(TOTAL_BITS)
    ) data_serializer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bit_tick(bit_tick),
        .load_en(load_en),
        .shifting_active(shifting_active),
        .addr(addr),
        .data_in(data_in),
        .can_tx(can_tx)
    );

endmodule

// Module to generate a tick pulse every BIT_TIME clock cycles
module can_bit_timer #(
    parameter BIT_TIME = 100
)(
    input wire clk,
    input wire rst_n,
    output reg bit_tick
);

    // Calculate width needed for timer count (counts from 0 to BIT_TIME-1)
    localparam TIMER_WIDTH = (BIT_TIME > 1) ? $clog2(BIT_TIME) : 1;
    reg [TIMER_WIDTH-1:0] timer_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count <= {TIMER_WIDTH{1'b0}};
            bit_tick <= 1'b0;
        end else begin
            if (timer_count < BIT_TIME - 1) begin
                timer_count <= timer_count + 1;
                bit_tick <= 1'b0;
            end else begin
                timer_count <= {TIMER_WIDTH{1'b0}};
                bit_tick <= 1'b1; // Pulse high for one clock cycle
            end
        end
    end

endmodule

// Module to control the transmission process (counting, load enable, complete signal)
module can_tx_controller #(
    parameter TOTAL_BITS = 24, // ADDR_WIDTH + DATA_WIDTH + 3
    parameter COUNTER_WIDTH = 5 // $clog2(TOTAL_BITS + 1)
)(
    input wire clk,
    input wire rst_n,
    input wire bit_tick, // Pulse from bit timer
    input wire transmit_en_buf, // Buffered transmit enable
    output reg load_en,      // Enable loading the serializer
    output reg tx_complete,   // Transmission complete signal
    output wire shifting_active // Indicates if shifting is currently happening
);

    reg [COUNTER_WIDTH-1:0] bit_counter; // Counter for bits transmitted

    // Shifting is active when the counter is less than TOTAL_BITS
    // Counter counts from 0 to TOTAL_BITS. Shifting happens for counts 0 to TOTAL_BITS-1.
    assign shifting_active = (bit_counter < TOTAL_BITS);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= {COUNTER_WIDTH{1'b0}};
            load_en <= 1'b0;
            tx_complete <= 1'b0;
        end else begin
            load_en <= 1'b0; // Default to low
            tx_complete <= 1'b0; // Default to low

            if (bit_tick) begin
                if (shifting_active) begin // bit_counter < TOTAL_BITS
                    // Increment counter during transmission
                    bit_counter <= bit_counter + 1;
                end else begin // bit_counter == TOTAL_BITS (End of transmission)
                    // Reset bit counter
                    bit_counter <= {COUNTER_WIDTH{1'b0}};
                    tx_complete <= 1'b1; // Signal completion

                    // Check if a new transmission should start
                    if (transmit_en_buf) begin
                        load_en <= 1'b1; // Enable loading for the next cycle
                    end
                end
            end
        end
    end

endmodule

// Module to hold and serialize the data for transmission
module can_data_serializer #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter TOTAL_BITS = ADDR_WIDTH + DATA_WIDTH + 3
)(
    input wire clk,
    input wire rst_n,
    input wire bit_tick, // Pulse from bit timer
    input wire load_en,  // Enable loading data
    input wire shifting_active, // Indicates if shifting is active
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire can_tx
);

    reg [TOTAL_BITS-1:0] shift_reg;

    // Output the current MSB of the shift register
    assign can_tx = shift_reg[TOTAL_BITS-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= {TOTAL_BITS{1'b0}};
        end else begin
            if (load_en) begin
                // Load new data when requested (at the end of a transmission cycle)
                shift_reg <= {3'b101, addr, data_in};
            end else if (bit_tick && shifting_active) begin
                // Shift data out on each bit tick if shifting is active
                shift_reg <= {shift_reg[TOTAL_BITS-2:0], 1'b0};
            end
            // If not load_en and not (bit_tick && shifting_active), shift_reg holds its value
        end
    end

endmodule