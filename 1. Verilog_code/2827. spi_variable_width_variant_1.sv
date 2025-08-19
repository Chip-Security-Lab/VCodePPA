//SystemVerilog
module spi_variable_width(
    input clk,
    input rst_n,
    input [4:0] data_width, // 1-32 bits
    input [31:0] tx_data,
    input start_tx,
    output reg [31:0] rx_data,
    output reg tx_done,

    output sclk,
    output cs_n,
    output mosi,
    input miso
);

// Stage 1: Input Latching & Start Condition
reg [31:0] tx_shift_reg_stage1, tx_shift_reg_stage2, tx_shift_reg_stage3;
reg [31:0] rx_shift_reg_stage1, rx_shift_reg_stage2, rx_shift_reg_stage3;
reg [4:0]  bit_counter_stage1, bit_counter_stage2, bit_counter_stage3;
reg [4:0]  data_width_stage1, data_width_stage2, data_width_stage3;
reg        busy_flag_stage1, busy_flag_stage2, busy_flag_stage3;
reg        sclk_reg_stage1, sclk_reg_stage2, sclk_reg_stage3;
reg        tx_done_stage1, tx_done_stage2, tx_done_stage3;
reg        miso_sample_stage1, miso_sample_stage2, miso_sample_stage3;

wire [31:0] tx_shift_reg_next;
wire [31:0] rx_shift_reg_next;
wire [4:0]  bit_counter_next;
wire        busy_flag_next;
wire        sclk_reg_next;
wire        tx_done_next;

assign mosi = tx_shift_reg_stage3[31];
assign sclk = busy_flag_stage3 ? sclk_reg_stage3 : 1'b0;
assign cs_n = ~busy_flag_stage3;

// Pipeline Stage 1: Latch inputs and handle start condition
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg_stage1 <= 32'd0;
        rx_shift_reg_stage1 <= 32'd0;
        bit_counter_stage1  <= 5'd0;
        data_width_stage1   <= 5'd0;
        busy_flag_stage1    <= 1'b0;
        sclk_reg_stage1     <= 1'b0;
        tx_done_stage1      <= 1'b0;
        miso_sample_stage1  <= 1'b0;
    end else if (start_tx && !busy_flag_stage1) begin
        tx_shift_reg_stage1 <= tx_data << (32 - data_width);
        rx_shift_reg_stage1 <= 32'd0;
        bit_counter_stage1  <= data_width;
        data_width_stage1   <= data_width;
        busy_flag_stage1    <= 1'b1;
        sclk_reg_stage1     <= 1'b0;
        tx_done_stage1      <= 1'b0;
        miso_sample_stage1  <= miso;
    end else if (busy_flag_stage1) begin
        sclk_reg_stage1    <= ~sclk_reg_stage1;
        miso_sample_stage1 <= miso;
        tx_done_stage1     <= 1'b0;
        // Other signals passed to next stage
        tx_shift_reg_stage1 <= tx_shift_reg_stage1;
        rx_shift_reg_stage1 <= rx_shift_reg_stage1;
        bit_counter_stage1  <= bit_counter_stage1;
        data_width_stage1   <= data_width_stage1;
        busy_flag_stage1    <= busy_flag_stage1;
    end else begin
        tx_done_stage1 <= 1'b0;
    end
end

// Pipeline Stage 2: SCLK falling/rising edge logic and shift
reg [4:0] bit_counter_dec_stage2;
reg       sclk_falling_stage2;
reg       sclk_rising_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg_stage2 <= 32'd0;
        rx_shift_reg_stage2 <= 32'd0;
        bit_counter_stage2  <= 5'd0;
        data_width_stage2   <= 5'd0;
        busy_flag_stage2    <= 1'b0;
        sclk_reg_stage2     <= 1'b0;
        tx_done_stage2      <= 1'b0;
        miso_sample_stage2  <= 1'b0;
        bit_counter_dec_stage2 <= 5'd0;
        sclk_falling_stage2 <= 1'b0;
        sclk_rising_stage2  <= 1'b0;
    end else begin
        // Pass-through signals
        tx_shift_reg_stage2 <= tx_shift_reg_stage1;
        rx_shift_reg_stage2 <= rx_shift_reg_stage1;
        bit_counter_stage2  <= bit_counter_stage1;
        data_width_stage2   <= data_width_stage1;
        busy_flag_stage2    <= busy_flag_stage1;
        sclk_reg_stage2     <= sclk_reg_stage1;
        tx_done_stage2      <= tx_done_stage1;
        miso_sample_stage2  <= miso_sample_stage1;

        // Detect SCLK edge
        sclk_falling_stage2 <= (busy_flag_stage1 && sclk_reg_stage1);
        sclk_rising_stage2  <= (busy_flag_stage1 && ~sclk_reg_stage1);

        // Pre-calculate bit_counter - 1 for this cycle
        bit_counter_dec_stage2 <= conditional_sum_subtract_1(bit_counter_stage1);
    end
end

// Pipeline Stage 3: Shift registers, bit counter, busy logic
reg [31:0] rx_shift_reg_shifted_stage3;
reg [31:0] tx_shift_reg_shifted_stage3;
reg [4:0]  bit_counter_stage3_next;
reg        busy_flag_stage3_next;
reg        tx_done_stage3_next;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg_stage3 <= 32'd0;
        rx_shift_reg_stage3 <= 32'd0;
        bit_counter_stage3  <= 5'd0;
        data_width_stage3   <= 5'd0;
        busy_flag_stage3    <= 1'b0;
        sclk_reg_stage3     <= 1'b0;
        tx_done_stage3      <= 1'b0;
        miso_sample_stage3  <= 1'b0;
        rx_shift_reg_shifted_stage3 <= 32'd0;
        tx_shift_reg_shifted_stage3 <= 32'd0;
        bit_counter_stage3_next <= 5'd0;
        busy_flag_stage3_next    <= 1'b0;
        tx_done_stage3_next      <= 1'b0;
    end else begin
        // Default pass-through
        tx_shift_reg_stage3 <= tx_shift_reg_stage2;
        rx_shift_reg_stage3 <= rx_shift_reg_stage2;
        bit_counter_stage3  <= bit_counter_stage2;
        data_width_stage3   <= data_width_stage2;
        busy_flag_stage3    <= busy_flag_stage2;
        sclk_reg_stage3     <= sclk_reg_stage2;
        tx_done_stage3      <= tx_done_stage2;
        miso_sample_stage3  <= miso_sample_stage2;

        rx_shift_reg_shifted_stage3 <= rx_shift_reg_stage2;
        tx_shift_reg_shifted_stage3 <= tx_shift_reg_stage2;
        bit_counter_stage3_next     <= bit_counter_stage2;
        busy_flag_stage3_next       <= busy_flag_stage2;
        tx_done_stage3_next         <= tx_done_stage2;

        // SCLK falling edge: shift out, decrement counter
        if (sclk_falling_stage2 && busy_flag_stage2) begin
            tx_shift_reg_shifted_stage3 <= {tx_shift_reg_stage2[30:0], 1'b0};
            bit_counter_stage3_next     <= bit_counter_dec_stage2;
            if (bit_counter_dec_stage2 == 5'd1) begin
                busy_flag_stage3_next <= 1'b0;
                tx_done_stage3_next   <= 1'b1;
            end else begin
                busy_flag_stage3_next <= 1'b1;
                tx_done_stage3_next   <= 1'b0;
            end
        end

        // SCLK rising edge: sample MISO
        if (sclk_rising_stage2 && busy_flag_stage2) begin
            rx_shift_reg_shifted_stage3 <= {rx_shift_reg_stage2[30:0], miso_sample_stage2};
        end

        // Latch shifted values
        tx_shift_reg_stage3 <= tx_shift_reg_shifted_stage3;
        rx_shift_reg_stage3 <= rx_shift_reg_shifted_stage3;
        bit_counter_stage3  <= bit_counter_stage3_next;
        busy_flag_stage3    <= busy_flag_stage3_next;
        tx_done_stage3      <= tx_done_stage3_next;
    end
end

// Output stage: latch rx_data and tx_done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data <= 32'd0;
        tx_done <= 1'b0;
    end else begin
        if (tx_done_stage3) begin
            rx_data <= ((rx_shift_reg_stage3 << 1) | miso_sample_stage3) >> (32 - data_width_stage3);
            tx_done <= 1'b1;
        end else begin
            tx_done <= 1'b0;
        end
    end
end

// Pipelined 5-bit subtract-1 function
function [4:0] conditional_sum_subtract_1;
    input [4:0] value;
    reg [4:0] sum;
    reg [3:0] borrow;
    begin
        // Stage 0: subtract 1 from LSB
        sum[0] = value[0] ^ 1'b1;
        borrow[0] = ~value[0];

        // Stage 1: subtract borrow from bit 1
        sum[1] = value[1] ^ borrow[0];
        borrow[1] = ~value[1] & borrow[0];

        // Stage 2:
        sum[2] = value[2] ^ borrow[1];
        borrow[2] = ~value[2] & borrow[1];

        // Stage 3:
        sum[3] = value[3] ^ borrow[2];
        borrow[3] = ~value[3] & borrow[2];

        // Stage 4:
        sum[4] = value[4] ^ borrow[3];

        conditional_sum_subtract_1 = sum;
    end
endfunction

endmodule