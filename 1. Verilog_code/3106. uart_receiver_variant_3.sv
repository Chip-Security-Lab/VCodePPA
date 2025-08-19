//SystemVerilog
module uart_receiver(
    input wire clk,
    input wire rst,
    input wire rx,
    input wire baud_tick,
    output reg [7:0] data_out,
    output reg req,
    input wire ack
);

    parameter [2:0] IDLE = 3'b000, START_BIT = 3'b001, 
                    DATA_BITS = 3'b010, STOP_BIT = 3'b011;
                    
    reg [2:0] state, next_state;
    reg [3:0] bit_count;
    reg [3:0] tick_count;
    reg [7:0] rx_shift_reg;
    reg [7:0] rx_shift_reg_next;
    reg [7:0] data_out_next;
    reg req_next;
    reg [2:0] state_next;
    reg [3:0] bit_count_next;
    reg [3:0] tick_count_next;

    // Brent-Kung Adder implementation
    wire [7:0] sum;
    wire [7:0] carry;
    wire [7:0] a, b;
    assign a = rx_shift_reg_next;
    assign b = 8'b00000001;

    // Level 1
    assign carry[0] = a[0] & b[0];
    assign sum[0] = a[0] ^ b[0];

    // Level 2
    assign carry[1] = (a[1] & b[1]) | (carry[0] & (a[1] ^ b[1]));
    assign sum[1] = a[1] ^ b[1] ^ carry[0];

    assign carry[2] = (a[2] & b[2]) | (carry[1] & (a[2] ^ b[2]));
    assign sum[2] = a[2] ^ b[2] ^ carry[1];

    assign carry[3] = (a[3] & b[3]) | (carry[2] & (a[3] ^ b[3]));
    assign sum[3] = a[3] ^ b[3] ^ carry[2];

    assign carry[4] = (a[4] & b[4]) | (carry[3] & (a[4] ^ b[4]));
    assign sum[4] = a[4] ^ b[4] ^ carry[3];

    assign carry[5] = (a[5] & b[5]) | (carry[4] & (a[5] ^ b[5]));
    assign sum[5] = a[5] ^ b[5] ^ carry[4];

    assign carry[6] = (a[6] & b[6]) | (carry[5] & (a[6] ^ b[6]));
    assign sum[6] = a[6] ^ b[6] ^ carry[5];

    assign carry[7] = (a[7] & b[7]) | (carry[6] & (a[7] ^ b[7]));
    assign sum[7] = a[7] ^ b[7] ^ carry[6];

    // Next state logic
    always @(*) begin
        state_next = state;
        bit_count_next = bit_count;
        tick_count_next = tick_count;
        rx_shift_reg_next = rx_shift_reg;
        data_out_next = data_out;
        req_next = req;

        case (state)
            IDLE: begin
                req_next = 0;
                if (rx == 0)
                    state_next = START_BIT;
            end
            START_BIT: begin
                if (baud_tick) begin
                    if (tick_count == 4'h7) begin
                        state_next = DATA_BITS;
                        tick_count_next = 0;
                        bit_count_next = 0;
                    end else
                        tick_count_next = tick_count + 1;
                end
            end
            DATA_BITS: begin
                if (baud_tick) begin
                    if (tick_count == 4'hF) begin
                        rx_shift_reg_next = {rx, rx_shift_reg[7:1]};
                        tick_count_next = 0;
                        if (bit_count == 7)
                            state_next = STOP_BIT;
                        else
                            bit_count_next = bit_count + 1;
                    end else
                        tick_count_next = tick_count + 1;
                end
            end
            STOP_BIT: begin
                if (baud_tick) begin
                    if (tick_count == 4'hF) begin
                        data_out_next = rx_shift_reg;
                        req_next = 1;
                        state_next = IDLE;
                    end else
                        tick_count_next = tick_count + 1;
                end
            end
        endcase

        if (req && ack)
            req_next = 0;
    end

    // Register update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_count <= 0;
            tick_count <= 0;
            rx_shift_reg <= 0;
            data_out <= 0;
            req <= 0;
        end else begin
            state <= state_next;
            bit_count <= bit_count_next;
            tick_count <= tick_count_next;
            rx_shift_reg <= rx_shift_reg_next;
            data_out <= data_out_next;
            req <= req_next;
        end
    end

endmodule