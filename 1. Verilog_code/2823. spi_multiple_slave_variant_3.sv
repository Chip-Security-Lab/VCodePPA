//SystemVerilog
module spi_multiple_slave #(
    parameter SLAVE_COUNT = 4,
    parameter DATA_WIDTH = 8
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] tx_data,
    input [$clog2(SLAVE_COUNT)-1:0] slave_select,
    input start_transfer,
    output [DATA_WIDTH-1:0] rx_data,
    output transfer_done,

    output spi_clk,
    output [SLAVE_COUNT-1:0] spi_cs_n,
    output spi_mosi,
    input [SLAVE_COUNT-1:0] spi_miso
);

    reg [DATA_WIDTH-1:0] shift_reg_d, shift_reg_q;
    reg [$clog2(DATA_WIDTH):0] bit_count_d, bit_count_q;
    reg busy_d, busy_q;
    reg spi_clk_en_d, spi_clk_en_q;
    reg [SLAVE_COUNT-1:0] spi_cs_n_d, spi_cs_n_q;
    reg transfer_done_d, transfer_done_q;
    reg [DATA_WIDTH-1:0] rx_data_d, rx_data_q;

    wire active_miso;
    wire spi_clk_int;
    wire spi_clk_rising_edge;
    reg spi_clk_q;

    assign spi_clk_int = busy_q ? clk : 1'b0;
    assign spi_clk = spi_clk_int;
    assign spi_mosi = shift_reg_q[DATA_WIDTH-1];
    assign active_miso = spi_miso[slave_select];
    assign spi_cs_n = spi_cs_n_q;
    assign rx_data = rx_data_q;
    assign transfer_done = transfer_done_q;

    // Detect rising edge of spi_clk_int
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_clk_q <= 1'b0;
        end else begin
            spi_clk_q <= spi_clk_int;
        end
    end
    assign spi_clk_rising_edge = (spi_clk_int == 1'b1) && (spi_clk_q == 1'b0);

    // Move registers before output assignment (retiming)
    always @(*) begin
        // Default assignments
        shift_reg_d = shift_reg_q;
        bit_count_d = bit_count_q;
        busy_d = busy_q;
        spi_cs_n_d = spi_cs_n_q;
        transfer_done_d = 1'b0;
        rx_data_d = rx_data_q;

        if (!rst_n) begin
            shift_reg_d = {DATA_WIDTH{1'b0}};
            bit_count_d = {($clog2(DATA_WIDTH)+1){1'b0}};
            busy_d = 1'b0;
            spi_cs_n_d = {SLAVE_COUNT{1'b1}};
            transfer_done_d = 1'b0;
            rx_data_d = {DATA_WIDTH{1'b0}};
        end else if (start_transfer && !busy_q) begin
            shift_reg_d = tx_data;
            bit_count_d = DATA_WIDTH;
            busy_d = 1'b1;
            spi_cs_n_d = ~(1'b1 << slave_select);
            transfer_done_d = 1'b0;
            rx_data_d = rx_data_q;
        end else if (busy_q && bit_count_q > 0) begin
            if (spi_clk_rising_edge) begin
                shift_reg_d = {shift_reg_q[DATA_WIDTH-2:0], active_miso};
                bit_count_d = bit_count_q - 1;
                if (bit_count_q == 1) begin
                    busy_d = 1'b0;
                    transfer_done_d = 1'b1;
                    rx_data_d = {shift_reg_q[DATA_WIDTH-2:0], active_miso};
                    spi_cs_n_d = {SLAVE_COUNT{1'b1}};
                end else begin
                    busy_d = busy_q;
                    spi_cs_n_d = spi_cs_n_q;
                    rx_data_d = rx_data_q;
                end
            end else begin
                shift_reg_d = shift_reg_q;
                bit_count_d = bit_count_q;
                busy_d = busy_q;
                spi_cs_n_d = spi_cs_n_q;
                rx_data_d = rx_data_q;
            end
        end
    end

    // Sequential logic for all registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_q <= {DATA_WIDTH{1'b0}};
            bit_count_q <= {($clog2(DATA_WIDTH)+1){1'b0}};
            busy_q <= 1'b0;
            spi_cs_n_q <= {SLAVE_COUNT{1'b1}};
            transfer_done_q <= 1'b0;
            rx_data_q <= {DATA_WIDTH{1'b0}};
        end else begin
            shift_reg_q <= shift_reg_d;
            bit_count_q <= bit_count_d;
            busy_q <= busy_d;
            spi_cs_n_q <= spi_cs_n_d;
            transfer_done_q <= transfer_done_d;
            rx_data_q <= rx_data_d;
        end
    end

endmodule