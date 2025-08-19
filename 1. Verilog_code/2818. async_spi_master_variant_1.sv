//SystemVerilog
module async_spi_master(
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire begin_xfer,
    output wire [15:0] data_out,
    output wire xfer_done,
    // SPI Interface
    output wire sck,
    output wire ss_n,
    output wire mosi,
    input wire miso
);

    // Pipeline Stage 1: Command latch, shift register load, bit counter, and SCK
    reg [15:0] shift_reg_stage1;
    reg [4:0]  bit_cnt_stage1;
    reg        running_stage1;
    reg        sck_r_stage1;
    reg        valid_stage1;
    reg        flush_stage1;

    // Output registers
    reg [15:0] data_out_reg;
    reg        xfer_done_reg;
    reg        sck_reg;
    reg        ss_n_reg;
    reg        mosi_reg;

    // Assign outputs
    assign data_out  = data_out_reg;
    assign xfer_done = xfer_done_reg;
    assign sck       = sck_reg;
    assign ss_n      = ss_n_reg;
    assign mosi      = mosi_reg;

    // Combined Stage: Latch input, load shift register, update shift, and control logic
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage1 <= 16'd0;
            bit_cnt_stage1   <= 5'd0;
            running_stage1   <= 1'b0;
            sck_r_stage1     <= 1'b0;
            valid_stage1     <= 1'b0;
            flush_stage1     <= 1'b1;
        end else begin
            if (!running_stage1 && begin_xfer) begin
                shift_reg_stage1 <= data_in;
                bit_cnt_stage1   <= 5'd16;
                running_stage1   <= 1'b1;
                sck_r_stage1     <= 1'b0;
            end else if (running_stage1) begin
                sck_r_stage1 <= ~sck_r_stage1;
                if (sck_r_stage1) begin // falling edge
                    if (bit_cnt_stage1 == 0)
                        running_stage1 <= 1'b0;
                    else
                        bit_cnt_stage1 <= bit_cnt_stage1 - 5'd1;
                end else begin // rising edge
                    shift_reg_stage1 <= {shift_reg_stage1[14:0], miso};
                end
            end
            valid_stage1 <= running_stage1 | begin_xfer;
            flush_stage1 <= rst;
        end
    end

    // Output registers: output logic
    always @(posedge clk) begin
        if (rst) begin
            data_out_reg   <= 16'd0;
            xfer_done_reg  <= 1'b1;
            sck_reg        <= 1'b0;
            ss_n_reg       <= 1'b1;
            mosi_reg       <= 1'b0;
        end else begin
            data_out_reg   <= shift_reg_stage1;
            xfer_done_reg  <= ~running_stage1;
            ss_n_reg       <= ~running_stage1;
            sck_reg        <= running_stage1 ? sck_r_stage1 : 1'b0;
            mosi_reg       <= shift_reg_stage1[15];
        end
    end

endmodule