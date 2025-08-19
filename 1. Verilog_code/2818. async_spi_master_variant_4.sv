//SystemVerilog
module async_spi_master(
    input clk,
    input rst,
    input [15:0] data_in,
    input begin_xfer,
    output [15:0] data_out,
    output xfer_done,

    // SPI Interface
    output sck,
    output ss_n,
    output mosi,
    input miso
);

    // Pipeline stage 1: Input latch and transfer start detection
    reg [15:0] data_in_stage1;
    reg begin_xfer_stage1;
    reg rst_stage1;

    // Pipeline stage 2: State update
    reg [15:0] shift_reg_stage2;
    reg [4:0] bit_cnt_stage2;
    reg running_stage2;
    reg sck_r_stage2;
    reg miso_stage2;

    // Pipeline stage 3: Output and control
    reg [15:0] shift_reg_stage3;
    reg [4:0] bit_cnt_stage3;
    reg running_stage3;
    reg sck_r_stage3;

    // Valid signals for pipeline stages
    reg valid_stage1, valid_stage2, valid_stage3;
    reg flush_stage1, flush_stage2, flush_stage3;

    // Internal combinational signals for next state
    wire [15:0] shift_reg_next_stage2;
    wire [4:0] bit_cnt_next_stage2;
    wire running_next_stage2, sck_r_next_stage2;
    wire bit_cnt_zero_stage2;
    wire sck_falling_edge_stage2, sck_rising_edge_stage2;

    // Pipeline flush logic
    wire flush_pipeline = rst;

    // Stage 1: Latch input and begin_xfer
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1    <= 16'd0;
            begin_xfer_stage1 <= 1'b0;
            rst_stage1        <= 1'b1;
            valid_stage1      <= 1'b0;
            flush_stage1      <= 1'b0;
        end else begin
            data_in_stage1    <= data_in;
            begin_xfer_stage1 <= begin_xfer;
            rst_stage1        <= rst;
            valid_stage1      <= 1'b1;
            flush_stage1      <= flush_pipeline;
        end
    end

    // Stage 2: State update and SPI core logic
    always @(posedge clk) begin
        if (rst || flush_stage1) begin
            shift_reg_stage2 <= 16'd0;
            bit_cnt_stage2   <= 5'd0;
            running_stage2   <= 1'b0;
            sck_r_stage2     <= 1'b0;
            miso_stage2      <= 1'b0;
            valid_stage2     <= 1'b0;
            flush_stage2     <= 1'b0;
        end else if (valid_stage1) begin
            // SCK edge detection
            miso_stage2      <= miso;
            // State update logic
            shift_reg_stage2 <= shift_reg_next_stage2;
            bit_cnt_stage2   <= bit_cnt_next_stage2;
            running_stage2   <= running_next_stage2;
            sck_r_stage2     <= sck_r_next_stage2;
            valid_stage2     <= 1'b1;
            flush_stage2     <= flush_stage1;
        end else begin
            valid_stage2     <= 1'b0;
            flush_stage2     <= flush_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clk) begin
        if (rst || flush_stage2) begin
            shift_reg_stage3 <= 16'd0;
            bit_cnt_stage3   <= 5'd0;
            running_stage3   <= 1'b0;
            sck_r_stage3     <= 1'b0;
            valid_stage3     <= 1'b0;
            flush_stage3     <= 1'b0;
        end else if (valid_stage2) begin
            shift_reg_stage3 <= shift_reg_stage2;
            bit_cnt_stage3   <= bit_cnt_stage2;
            running_stage3   <= running_stage2;
            sck_r_stage3     <= sck_r_stage2;
            valid_stage3     <= 1'b1;
            flush_stage3     <= flush_stage2;
        end else begin
            valid_stage3     <= 1'b0;
            flush_stage3     <= flush_stage2;
        end
    end

    // Combinational logic for stage 2 state update
    // SCK edge detection
    assign sck_falling_edge_stage2 = running_stage2 && (sck_r_stage2 == 1'b1);
    assign sck_rising_edge_stage2  = running_stage2 && (sck_r_stage2 == 1'b0);

    assign bit_cnt_zero_stage2 = (bit_cnt_stage2 == 5'd0);

    // SCK next value
    assign sck_r_next_stage2 = (rst_stage1) ? 1'b0 :
                               (!running_stage2 && begin_xfer_stage1) ? 1'b0 :
                               (running_stage2) ? ~sck_r_stage2 :
                               sck_r_stage2;

    // Running next
    assign running_next_stage2 = (rst_stage1) ? 1'b0 :
                                 (!running_stage2 && begin_xfer_stage1) ? 1'b1 :
                                 (running_stage2 && sck_falling_edge_stage2 && bit_cnt_zero_stage2) ? 1'b0 :
                                 running_stage2;

    // Bit counter next
    assign bit_cnt_next_stage2 = (rst_stage1) ? 5'd0 :
                                 (!running_stage2 && begin_xfer_stage1) ? 5'd16 :
                                 (running_stage2 && sck_falling_edge_stage2 && !bit_cnt_zero_stage2) ? (bit_cnt_stage2 - 5'd1) :
                                 bit_cnt_stage2;

    // Shift register next
    assign shift_reg_next_stage2 = (rst_stage1) ? 16'd0 :
                                   (!running_stage2 && begin_xfer_stage1) ? data_in_stage1 :
                                   (running_stage2 && sck_rising_edge_stage2) ? {shift_reg_stage2[14:0], miso_stage2} :
                                   shift_reg_stage2;

    // Output assignments from the last pipeline stage
    assign mosi      = shift_reg_stage3[15];
    assign data_out  = shift_reg_stage3;
    assign xfer_done = ~running_stage3;
    assign ss_n      = ~running_stage3;
    assign sck       = running_stage3 ? sck_r_stage3 : 1'b0;

endmodule