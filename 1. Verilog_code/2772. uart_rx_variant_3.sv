//SystemVerilog
module uart_rx #(parameter DWIDTH = 8, SBIT = 1) (
    input wire clk,
    input wire rst_n,
    input wire rx_line,
    output reg rx_ready,
    output reg [DWIDTH-1:0] rx_data,
    output reg frame_err
);
    // State encoding
    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    reg [1:0] state_reg, state_next;
    reg [3:0] bit_count_reg, bit_count_next;
    reg [4:0] clk_count_reg, clk_count_next;
    reg [DWIDTH-1:0] shift_reg, shift_next;
    reg rx_ready_int_reg, rx_ready_int_next;
    reg frame_err_int_reg, frame_err_int_next;

    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_reg <= IDLE;
        else
            state_reg <= state_next;
    end

    // Bit Counter Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_count_reg <= 4'd0;
        else
            bit_count_reg <= bit_count_next;
    end

    // Clock Counter Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_count_reg <= 5'd0;
        else
            clk_count_reg <= clk_count_next;
    end

    // Data Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {DWIDTH{1'b0}};
        else
            shift_reg <= shift_next;
    end

    // RX Ready Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_ready_int_reg <= 1'b0;
        else
            rx_ready_int_reg <= rx_ready_int_next;
    end

    // Frame Error Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            frame_err_int_reg <= 1'b0;
        else
            frame_err_int_reg <= frame_err_int_next;
    end

    // Next State and Control Logic
    always @(*) begin
        // Default assignments
        state_next         = state_reg;
        bit_count_next     = bit_count_reg;
        clk_count_next     = clk_count_reg;
        shift_next         = shift_reg;
        rx_ready_int_next  = 1'b0;
        frame_err_int_next = frame_err_int_reg;

        case (state_reg)
            IDLE: begin
                clk_count_next     = 5'd0;
                bit_count_next     = 4'd0;
                shift_next         = {DWIDTH{1'b0}};
                frame_err_int_next = 1'b0;
                if (~rx_line)
                    state_next = START;
            end

            START: begin
                clk_count_next = clk_count_reg + 1'b1;
                // clk_count_reg == 5'd7 <=> clk_count_reg[4:3]==2'b00 && clk_count_reg[2:0]==3'b111
                if (clk_count_reg == 5'd7) begin
                    state_next      = DATA;
                    clk_count_next  = 5'd0;
                    bit_count_next  = 4'd0;
                end
            end

            DATA: begin
                clk_count_next = clk_count_reg + 1'b1;
                // clk_count_reg == 5'd15 <=> clk_count_reg[4]==1'b0 && clk_count_reg[3:0]==4'hF
                if (clk_count_reg == 5'd15) begin
                    clk_count_next = 5'd0;
                    shift_next = {rx_line, shift_reg[DWIDTH-1:1]};
                    bit_count_next = bit_count_reg + 1'b1;
                    if (bit_count_reg == (DWIDTH-1))
                        state_next = STOP;
                end
            end

            STOP: begin
                clk_count_next = clk_count_reg + 1'b1;
                if (clk_count_reg == 5'd15) begin
                    state_next         = IDLE;
                    rx_ready_int_next  = 1'b1;
                    frame_err_int_next = ~rx_line;
                end
            end

            default: begin
                state_next         = IDLE;
                clk_count_next     = 5'd0;
                bit_count_next     = 4'd0;
                shift_next         = {DWIDTH{1'b0}};
                rx_ready_int_next  = 1'b0;
                frame_err_int_next = 1'b0;
            end
        endcase
    end

    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_data <= {DWIDTH{1'b0}};
        else if (state_reg == STOP && clk_count_reg == 5'd15)
            rx_data <= shift_reg;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_ready <= 1'b0;
        else
            rx_ready <= rx_ready_int_reg;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            frame_err <= 1'b0;
        else
            frame_err <= frame_err_int_reg;
    end

endmodule