//SystemVerilog
module uart_tx_parity #(parameter DWIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire tx_en,
    input wire [DWIDTH-1:0] data_in,
    input wire [1:0] parity_mode, // 00:none, 01:odd, 10:even
    output reg tx_out,
    output reg tx_active
);

    localparam IDLE = 3'd0,
               START_BIT = 3'd1,
               DATA_BITS = 3'd2,
               PARITY_BIT = 3'd3,
               STOP_BIT = 3'd4;

    reg [2:0] state, state_next;
    reg [3:0] bit_index, bit_index_next;
    reg [DWIDTH-1:0] data_reg, data_reg_next;
    reg parity, parity_next;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= state_next;
    end

    // Bit index register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_index <= 4'd0;
        else
            bit_index <= bit_index_next;
    end

    // Data register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= {DWIDTH{1'b0}};
        else
            data_reg <= data_reg_next;
    end

    // Parity register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parity <= 1'b0;
        else
            parity <= parity_next;
    end

    // Output tx_active
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_active <= 1'b0;
        else if ((state == IDLE && tx_en) || (state_next != IDLE))
            tx_active <= 1'b1;
        else if (state == STOP_BIT)
            tx_active <= 1'b0;
    end

    // Output tx_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_out <= 1'b1;
        else begin
            case (state)
                IDLE: begin
                    if (!tx_en)
                        tx_out <= 1'b1;
                    else
                        tx_out <= 1'b1;
                end
                START_BIT: tx_out <= 1'b0;
                DATA_BITS: tx_out <= data_reg[0];
                PARITY_BIT: tx_out <= parity;
                STOP_BIT: tx_out <= 1'b1;
                default: tx_out <= 1'b1;
            endcase
        end
    end

    // Next state and datapath logic
    always @(*) begin
        // Default assignments
        state_next = state;
        bit_index_next = bit_index;
        data_reg_next = data_reg;
        parity_next = parity;

        case (state)
            IDLE: begin
                if (tx_en) begin
                    state_next = START_BIT;
                    data_reg_next = data_in;
                    bit_index_next = 4'd0;
                    parity_next = ^data_in ^ parity_mode[0];
                end
            end
            START_BIT: begin
                state_next = DATA_BITS;
                bit_index_next = 4'd0;
            end
            DATA_BITS: begin
                data_reg_next = {1'b0, data_reg[DWIDTH-1:1]};
                if (bit_index < DWIDTH-1) begin
                    bit_index_next = bit_index + 1'b1;
                end else begin
                    if (parity_mode == 2'b00)
                        state_next = STOP_BIT;
                    else
                        state_next = PARITY_BIT;
                end
            end
            PARITY_BIT: begin
                state_next = STOP_BIT;
            end
            STOP_BIT: begin
                state_next = IDLE;
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule