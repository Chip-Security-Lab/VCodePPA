//SystemVerilog
module uart_tx_mealy(
    input wire clk, rst_n,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_busy, tx_out
);
    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state, next_state;
    reg [2:0] bit_index;
    reg [7:0] data_reg;
    
    reg [1:0] state_buf1, state_buf2;
    reg [2:0] bit_index_buf;
    reg tx_out_buf;
    reg next_state_buf;

    // State buffer pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_buf1 <= IDLE;
            state_buf2 <= IDLE;
        end else begin
            state_buf1 <= state;
            state_buf2 <= state_buf1;
        end
    end

    // Bit index buffer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_index_buf <= 0;
        else
            bit_index_buf <= bit_index;
    end

    // Main state machine registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_index <= 0;
            data_reg <= 0;
        end else begin
            state <= next_state_buf;
            if (state_buf2 == IDLE && tx_start)
                data_reg <= tx_data;
            if (state_buf2 == DATA)
                bit_index <= (bit_index_buf == 3'd7) ? 3'd0 : bit_index_buf + 3'd1;
        end
    end

    // Busy signal generation
    always @(*) begin
        tx_busy = (state_buf2 != IDLE);
    end

    // Next state and output logic
    always @(*) begin
        case (state_buf2)
            IDLE: begin
                tx_out_buf = 1'b1;
                next_state_buf = tx_start ? START : IDLE;
            end
            START: begin
                tx_out_buf = 1'b0;
                next_state_buf = DATA;
            end
            DATA: begin
                tx_out_buf = data_reg[bit_index_buf];
                next_state_buf = (bit_index_buf == 3'd7) ? STOP : DATA;
            end
            STOP: begin
                tx_out_buf = 1'b1;
                next_state_buf = IDLE;
            end
            default: begin
                tx_out_buf = 1'b1;
                next_state_buf = IDLE;
            end
        endcase
    end

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_out <= 1'b1;
        else
            tx_out <= tx_out_buf;
    end
endmodule