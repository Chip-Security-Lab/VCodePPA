//SystemVerilog
module uart_rx_parity (
    input wire clk,
    input wire rst_n,
    input wire rx_in,
    input wire [1:0] parity_type, // 00:none, 01:odd, 10:even
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg parity_err
);

    localparam IDLE   = 3'd0,
               START  = 3'd1,
               DATA   = 3'd2,
               PARITY = 3'd3,
               STOP   = 3'd4;

    // State and buffer registers
    reg [2:0] state_reg, state_next;
    reg [2:0] state_buf1_reg, state_buf2_reg;

    // Bit index and buffer registers
    reg [2:0] bit_idx_reg, bit_idx_next;
    reg [2:0] bit_idx_buf1_reg, bit_idx_buf2_reg;

    // Data registers
    reg [7:0] data_reg, data_next;

    // Parity type buffers
    reg [1:0] parity_type_reg, parity_type_buf1_reg, parity_type_buf2_reg;

    // STOP buffer
    reg stop_buf1_reg, stop_buf2_reg;

    // Parity calculation buffer
    reg parity_calc_reg, parity_calc_next;

    // Output data buffer
    reg [7:0] rx_data_buf_reg, rx_data_buf_next;

    // Output valid buffer
    reg rx_valid_next;

    // Parity error buffer
    reg parity_err_next;

    // Internal signals for path balancing
    wire is_stop_state;
    wire is_data_last_bit;
    wire use_parity;
    wire parity_bit_expected;

    assign is_stop_state = (state_reg == STOP);
    assign is_data_last_bit = (bit_idx_buf2_reg == 3'd7);
    assign use_parity = (parity_type_buf2_reg != 2'b00);

    // Pre-compute next parity
    assign parity_bit_expected = (^data_next) ^ parity_type_buf2_reg[0];

    // Sequential logic with reset and buffered fanout signals
    always @(posedge clk) begin
        if (!rst_n) begin
            state_reg            <= IDLE;
            state_buf1_reg       <= IDLE;
            state_buf2_reg       <= IDLE;

            bit_idx_reg          <= 3'd0;
            bit_idx_buf1_reg     <= 3'd0;
            bit_idx_buf2_reg     <= 3'd0;

            data_reg             <= 8'd0;

            parity_type_reg      <= 2'b00;
            parity_type_buf1_reg <= 2'b00;
            parity_type_buf2_reg <= 2'b00;

            stop_buf1_reg        <= 1'b0;
            stop_buf2_reg        <= 1'b0;

            parity_calc_reg      <= 1'b0;

            rx_data_buf_reg      <= 8'd0;
            rx_data              <= 8'd0;
            rx_valid             <= 1'b0;
            parity_err           <= 1'b0;
        end else begin
            // Buffering state, bit_idx, parity_type, STOP
            state_reg            <= state_next;
            state_buf1_reg       <= state_reg;
            state_buf2_reg       <= state_buf1_reg;

            bit_idx_reg          <= bit_idx_next;
            bit_idx_buf1_reg     <= bit_idx_reg;
            bit_idx_buf2_reg     <= bit_idx_buf1_reg;

            data_reg             <= data_next;

            parity_type_reg      <= parity_type;
            parity_type_buf1_reg <= parity_type_reg;
            parity_type_buf2_reg <= parity_type_buf1_reg;

            stop_buf1_reg        <= is_stop_state;
            stop_buf2_reg        <= stop_buf1_reg;

            parity_calc_reg      <= parity_calc_next;

            rx_data_buf_reg      <= rx_data_buf_next;
            rx_data              <= rx_data_buf_reg;
            rx_valid             <= rx_valid_next;
            parity_err           <= parity_err_next;
        end
    end

    // Combinational logic with path balancing
    always @(*) begin
        // Defaults
        state_next         = state_reg;
        bit_idx_next       = bit_idx_reg;
        data_next          = data_reg;
        parity_calc_next   = parity_calc_reg;
        rx_data_buf_next   = rx_data_buf_reg;
        rx_valid_next      = 1'b0;
        parity_err_next    = parity_err;

        // Path-balanced state transitions and outputs
        case (state_buf2_reg)
            IDLE: begin
                if (rx_in == 1'b0)
                    state_next = START;
            end
            START: begin
                state_next = DATA;
            end
            DATA: begin
                data_next = {rx_in, data_reg[7:1]};
                if (is_data_last_bit) begin
                    bit_idx_next = 3'd0;
                    if (use_parity) begin
                        state_next = PARITY;
                    end else begin
                        state_next = STOP;
                    end
                    parity_calc_next = (^data_next) ^ parity_type_buf2_reg[0];
                end else begin
                    bit_idx_next = bit_idx_buf2_reg + 3'd1;
                end
            end
            PARITY: begin
                state_next = STOP;
            end
            STOP: begin
                state_next = IDLE;
            end
            default: begin
                state_next = IDLE;
            end
        endcase

        // Output data and flags at STOP->IDLE transition
        if (stop_buf2_reg && (state_next == IDLE)) begin
            rx_data_buf_next = data_reg;
            rx_valid_next    = 1'b1;
            if (parity_type_buf2_reg != 2'b00)
                parity_err_next = (parity_calc_reg != rx_in);
            else
                parity_err_next = 1'b0;
        end else begin
            rx_valid_next    = 1'b0;
        end
    end

endmodule