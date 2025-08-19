//SystemVerilog
module async_spi_master(
    input               clk,
    input               rst,
    input       [15:0]  data_in,
    input               begin_xfer,
    output      [15:0]  data_out,
    output              xfer_done,

    // SPI Interface
    output              sck,
    output              ss_n,
    output              mosi,
    input               miso
);

// Stage 1: Command Latch & Initial State
reg         [15:0]  data_in_latched;
reg                 begin_xfer_latched;
reg                 stage1_valid;

// Stage 2: SPI Shift Register & Bit Counter
reg         [15:0]  spi_shift_reg;
reg         [4:0]   spi_bit_cnt;
reg                 spi_running;
reg                 sck_r;
reg                 stage2_valid;

// Stage 3: Output Register
reg         [15:0]  output_data_reg;
reg                 transfer_done_reg;
reg                 ss_n_reg;
reg                 sck_reg;
reg                 mosi_reg;
reg                 stage3_valid;

// Pipeline flush signal
reg                 pipeline_flush;

// Valid signal chain
wire                stage1_to_2_valid;
wire                stage2_to_3_valid;

// SPI control signals
assign mosi      = mosi_reg;
assign data_out  = output_data_reg;
assign xfer_done = transfer_done_reg;
assign ss_n      = ss_n_reg;
assign sck       = sck_reg;

// Stage 1: Latch input and begin_xfer
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_in_latched       <= 16'd0;
        begin_xfer_latched    <= 1'b0;
        stage1_valid          <= 1'b0;
    end else begin
        if (begin_xfer && !stage1_valid) begin
            data_in_latched       <= data_in;
            begin_xfer_latched    <= 1'b1;
            stage1_valid          <= 1'b1;
        end else if (pipeline_flush) begin
            stage1_valid          <= 1'b0;
        end
    end
end

assign stage1_to_2_valid = stage1_valid;

// Optimized comparator logic for SPI bit counter & control
wire spi_start = stage1_to_2_valid && !spi_running;
wire spi_falling_edge = spi_running && sck_r;
wire spi_rising_edge  = spi_running && !sck_r;
wire spi_last_bit     = (spi_bit_cnt == 5'd1);

// Stage 2: SPI Shift Register and Bit Counter
always @(posedge clk or posedge rst) begin
    if (rst) begin
        spi_shift_reg   <= 16'd0;
        spi_bit_cnt     <= 5'd0;
        spi_running     <= 1'b0;
        sck_r           <= 1'b0;
        stage2_valid    <= 1'b0;
    end else begin
        if (spi_start) begin
            spi_shift_reg   <= data_in_latched;
            spi_bit_cnt     <= 5'd16;
            spi_running     <= 1'b1;
            sck_r           <= 1'b0;
            stage2_valid    <= 1'b1;
        end else if (spi_running) begin
            sck_r <= ~sck_r;
            if (sck_r) begin // falling edge
                if (spi_bit_cnt > 5'd1) begin
                    spi_bit_cnt <= spi_bit_cnt - 5'd1;
                end else begin
                    spi_running  <= 1'b0;
                    stage2_valid <= 1'b0;
                end
            end else begin // rising edge
                spi_shift_reg <= {spi_shift_reg[14:0], miso};
            end
        end
        if (pipeline_flush) begin
            stage2_valid    <= 1'b0;
            spi_running     <= 1'b0;
            sck_r           <= 1'b0;
            spi_bit_cnt     <= 5'd0;
            spi_shift_reg   <= 16'd0;
        end
    end
end

assign stage2_to_3_valid = stage2_valid;

// Stage 3: Output and SPI interface signals
wire running_inv = ~spi_running;
wire ss_n_next   = running_inv;
wire xfer_done_next = running_inv;
wire sck_next    = spi_running ? sck_r : 1'b0;
wire mosi_next   = spi_shift_reg[15];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        output_data_reg     <= 16'd0;
        transfer_done_reg   <= 1'b1;
        ss_n_reg            <= 1'b1;
        sck_reg             <= 1'b0;
        mosi_reg            <= 1'b0;
        stage3_valid        <= 1'b0;
    end else begin
        if (stage2_to_3_valid) begin
            output_data_reg     <= spi_shift_reg;
            transfer_done_reg   <= xfer_done_next;
            ss_n_reg            <= ss_n_next;
            sck_reg             <= sck_next;
            mosi_reg            <= mosi_next;
            stage3_valid        <= 1'b1;
        end else begin
            transfer_done_reg   <= 1'b1;
            ss_n_reg            <= 1'b1;
            sck_reg             <= 1'b0;
            mosi_reg            <= 1'b0;
            stage3_valid        <= 1'b0;
        end
        if (pipeline_flush) begin
            stage3_valid        <= 1'b0;
            transfer_done_reg   <= 1'b1;
            ss_n_reg            <= 1'b1;
            sck_reg             <= 1'b0;
            mosi_reg            <= 1'b0;
            output_data_reg     <= 16'd0;
        end
    end
end

// Pipeline flush logic: resets all pipeline stages on rst or a dedicated flush
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pipeline_flush <= 1'b1;
    end else begin
        pipeline_flush <= 1'b0;
    end
end

endmodule