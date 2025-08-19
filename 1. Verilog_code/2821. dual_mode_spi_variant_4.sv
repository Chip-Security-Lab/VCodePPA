//SystemVerilog
module dual_mode_spi(
    input               clk,
    input               rst_n,
    input               mode,         // 0: Standard, 1: Dual IO
    input   [7:0]       tx_data,
    input               start,
    output  reg [7:0]   rx_data,
    output  reg         done,
    output  reg         sck,
    output  reg         cs_n,
    inout               io0,          // MOSI in standard mode
    inout               io1           // MISO in standard mode
);

// ====== High fanout signal buffers ======

// Mode buffer (double buffer)
reg mode_buf1, mode_buf2;

// tx_data buffer (double buffer)
reg [7:0] tx_data_buf1, tx_data_buf2;

// done buffer (double buffer)
reg done_buf1, done_buf2;

// cs_n buffer (double buffer)
reg cs_n_buf1, cs_n_buf2;

// tx_shift_reg buffer (double buffer)
reg [7:0] tx_shift_reg_buf1, tx_shift_reg_buf2;

// ====== Core Registers ======
reg [7:0]   tx_shift_reg, rx_shift_reg;
reg [2:0]   bit_counter;
reg         io0_out_reg, io1_out_reg;
reg         io0_oe_reg, io1_oe_reg;

// ====== Internal wire ======
wire        bit_counter_zero;
assign      bit_counter_zero = (bit_counter == 3'd0);

// ====== Buffering high fanout signals ======
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mode_buf1        <= 1'b0;
        mode_buf2        <= 1'b0;
        tx_data_buf1     <= 8'h00;
        tx_data_buf2     <= 8'h00;
        done_buf1        <= 1'b0;
        done_buf2        <= 1'b0;
        cs_n_buf1        <= 1'b1;
        cs_n_buf2        <= 1'b1;
        tx_shift_reg_buf1 <= 8'h00;
        tx_shift_reg_buf2 <= 8'h00;
    end else begin
        mode_buf1        <= mode;
        mode_buf2        <= mode_buf1;
        tx_data_buf1     <= tx_data;
        tx_data_buf2     <= tx_data_buf1;
        done_buf1        <= done;
        done_buf2        <= done_buf1;
        cs_n_buf1        <= cs_n;
        cs_n_buf2        <= cs_n_buf1;
        tx_shift_reg_buf1 <= tx_shift_reg;
        tx_shift_reg_buf2 <= tx_shift_reg_buf1;
    end
end

// Tri-state buffer control
assign io0 = io0_oe_reg ? io0_out_reg : 1'bz;
assign io1 = io1_oe_reg ? io1_out_reg : 1'bz;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg    <= 8'h00;
        rx_shift_reg    <= 8'h00;
        bit_counter     <= 3'd0;
        sck             <= 1'b0;
        cs_n            <= 1'b1;
        done            <= 1'b0;
        io0_oe_reg      <= 1'b0;
        io1_oe_reg      <= 1'b0;
        io0_out_reg     <= 1'b0;
        io1_out_reg     <= 1'b0;
        rx_data         <= 8'h00;
    end else begin
        if (start && cs_n_buf2) begin
            tx_shift_reg    <= tx_data_buf2;
            bit_counter     <= mode_buf2 ? 3'd3 : 3'd7;
            cs_n            <= 1'b0;
            done            <= 1'b0;
            io0_oe_reg      <= 1'b1;
            io1_oe_reg      <= mode_buf2;
            io0_out_reg     <= mode_buf2 ? tx_data_buf2[1] : tx_data_buf2[7];
            io1_out_reg     <= mode_buf2 ? tx_data_buf2[0] : 1'b0;
            rx_shift_reg    <= 8'h00;
        end else if (!cs_n_buf2) begin
            sck <= ~sck;
            if (sck) begin // Rising edge
                if (mode_buf2) begin
                    rx_shift_reg <= {rx_shift_reg[5:0], io1, io0};
                end else begin
                    rx_shift_reg <= {rx_shift_reg[6:0], io1};
                end
                if (!bit_counter_zero)
                    bit_counter <= bit_counter - 3'd1;
            end else begin // Falling edge
                if (mode_buf2) begin
                    io0_out_reg <= tx_shift_reg_buf2[1];
                    io1_out_reg <= tx_shift_reg_buf2[0];
                    tx_shift_reg <= {tx_shift_reg_buf2[5:0], 2'b00};
                end else begin
                    io0_out_reg <= tx_shift_reg_buf2[7];
                    tx_shift_reg <= {tx_shift_reg_buf2[6:0], 1'b0};
                end
                if (bit_counter_zero) begin
                    cs_n        <= 1'b1;
                    done        <= 1'b1;
                    rx_data     <= rx_shift_reg;
                    io0_oe_reg  <= 1'b0;
                    io1_oe_reg  <= 1'b0;
                end
            end
        end else begin
            done <= 1'b0;
        end
    end
end

endmodule