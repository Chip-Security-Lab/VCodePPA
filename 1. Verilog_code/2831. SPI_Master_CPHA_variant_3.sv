//SystemVerilog
module SPI_Master_CPHA #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV = 4
)(
    input clk, rst_n,
    input start,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy, done,
    output sclk, mosi,
    input miso,
    output reg cs
);

reg [1:0] cpol_cpha; // [CPOL, CPHA]

// High-fanout signal buffer registers
reg [3:0] clk_cnt, clk_cnt_buf1, clk_cnt_buf2;
reg [DATA_WIDTH-1:0] shift_reg, shift_reg_buf1, shift_reg_buf2;
reg [2:0] state, state_buf;
reg sclk_int, sclk_int_buf1, sclk_int_buf2;
reg [$clog2(DATA_WIDTH):0] bit_cnt, bit_cnt_buf1, bit_cnt_buf2;
reg b0, b0_buf;
reg b1, b1_buf;

localparam IDLE = 0, PRE_SCLK = 1, SHIFT = 2, POST_SCLK = 3;

// Buffering high-fanout signals at every clock cycle
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt_buf1 <= 4'b0;
        clk_cnt_buf2 <= 4'b0;
        shift_reg_buf1 <= {DATA_WIDTH{1'b0}};
        shift_reg_buf2 <= {DATA_WIDTH{1'b0}};
        sclk_int_buf1 <= 1'b0;
        sclk_int_buf2 <= 1'b0;
        bit_cnt_buf1 <= 0;
        bit_cnt_buf2 <= 0;
        b0 <= 1'b0;
        b0_buf <= 1'b0;
        b1 <= 1'b0;
        b1_buf <= 1'b0;
        state_buf <= IDLE;
    end else begin
        clk_cnt_buf1 <= clk_cnt;
        clk_cnt_buf2 <= clk_cnt_buf1;
        shift_reg_buf1 <= shift_reg;
        shift_reg_buf2 <= shift_reg_buf1;
        sclk_int_buf1 <= sclk_int;
        sclk_int_buf2 <= sclk_int_buf1;
        bit_cnt_buf1 <= bit_cnt;
        bit_cnt_buf2 <= bit_cnt_buf1;
        b0_buf <= b0;
        b1_buf <= b1;
        state_buf <= state;
    end
end

// Optimized state machine with efficient comparison logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        busy <= 1'b0;
        done <= 1'b0;
        cs <= 1'b1;
        sclk_int <= 1'b0;
        clk_cnt <= 4'b0;
        bit_cnt <= 0;
        shift_reg <= 0;
        rx_data <= 0;
        cpol_cpha <= 2'b00;
        b0 <= 1'b0;
        b1 <= 1'b0;
    end else begin
        case (state)
        IDLE: begin
            if (start) begin
                state <= PRE_SCLK;
                shift_reg <= tx_data;
                busy <= 1'b1;
                cs <= 1'b0;
                clk_cnt <= 0;
                bit_cnt <= 0;
                b0 <= 1'b0;
                b1 <= 1'b0;
                done <= 1'b0;
            end else begin
                done <= 1'b0;
            end
        end
        PRE_SCLK: begin
            if (clk_cnt_buf2 >= (CLK_DIV >> 1)) begin
                state <= SHIFT;
                clk_cnt <= 0;
                sclk_int <= ~sclk_int_buf2;
                b0 <= ~b0_buf;
                b1 <= b1_buf;
            end else begin
                clk_cnt <= clk_cnt_buf2 + 1;
                b0 <= b0_buf;
                b1 <= b1_buf;
            end
        end
        SHIFT: begin
            if (clk_cnt_buf2 >= (CLK_DIV >> 1)) begin
                clk_cnt <= 0;
                sclk_int <= ~sclk_int_buf2;

                // Combine range check for bit_cnt, avoid chaining
                if (!sclk_int_buf2) begin
                    shift_reg <= {shift_reg_buf2[DATA_WIDTH-2:0], miso};
                end

                if ((!sclk_int_buf2) && (bit_cnt_buf2+1 >= DATA_WIDTH)) begin
                    state <= POST_SCLK;
                    rx_data <= {shift_reg_buf2[DATA_WIDTH-2:0], miso};
                    b0 <= b0_buf;
                    b1 <= ~b1_buf;
                end else if (!sclk_int_buf2) begin
                    bit_cnt <= bit_cnt_buf2 + 1;
                    b0 <= b0_buf;
                    b1 <= b1_buf;
                end else begin
                    b0 <= b0_buf;
                    b1 <= b1_buf;
                end
            end else begin
                clk_cnt <= clk_cnt_buf2 + 1;
                b0 <= b0_buf;
                b1 <= b1_buf;
            end
        end
        POST_SCLK: begin
            cs <= 1'b1;
            busy <= 1'b0;
            done <= 1'b1;
            state <= IDLE;
            b0 <= b0_buf;
            b1 <= b1_buf;
        end
        default: begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            cs <= 1'b1;
            sclk_int <= 1'b0;
            clk_cnt <= 4'b0;
            bit_cnt <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            cpol_cpha <= 2'b00;
            b0 <= 1'b0;
            b1 <= 1'b0;
        end
        endcase
    end
end

assign mosi = shift_reg_buf2[DATA_WIDTH-1];
assign sclk = (cpol_cpha[0] & (state_buf == SHIFT)) ? sclk_int_buf2 : cpol_cpha[1];

endmodule