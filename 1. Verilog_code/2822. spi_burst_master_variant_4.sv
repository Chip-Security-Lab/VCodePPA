//SystemVerilog
module spi_burst_master #(
    parameter DATA_WIDTH = 8,
    parameter BURST_SIZE = 4
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] tx_data [BURST_SIZE-1:0],
    input burst_start,
    output reg [DATA_WIDTH-1:0] rx_data [BURST_SIZE-1:0],
    output reg burst_done,
    output sclk,
    output cs_n,
    output mosi,
    input miso
);

    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH)-1:0] bit_count;
    reg [$clog2(BURST_SIZE)-1:0] burst_count;
    reg busy;
    reg sclk_int;

    assign sclk = (busy == 1'b1) ? sclk_int : 1'b0;
    assign cs_n = (busy == 1'b1) ? 1'b0 : 1'b1;
    assign mosi = shift_reg[DATA_WIDTH-1];

    integer i;

    // State encoding
    localparam [1:0] IDLE      = 2'b00;
    localparam [1:0] START     = 2'b01;
    localparam [1:0] TRANSFER  = 2'b10;

    reg [1:0] current_state, next_state;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Next state logic with if-else
    always @(*) begin
        if (current_state == IDLE) begin
            if (burst_start && !busy)
                next_state = START;
            else
                next_state = IDLE;
        end else if (current_state == START) begin
            next_state = TRANSFER;
        end else if (current_state == TRANSFER) begin
            if (busy)
                next_state = TRANSFER;
            else
                next_state = IDLE;
        end else begin
            next_state = IDLE;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            burst_done <= 1'b0;
            bit_count <= {($clog2(DATA_WIDTH)){1'b0}};
            burst_count <= {($clog2(BURST_SIZE)){1'b0}};
            sclk_int <= 1'b0;
            for (i = 0; i < BURST_SIZE; i = i + 1) begin
                rx_data[i] <= {DATA_WIDTH{1'b0}};
            end
            shift_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            if (current_state == IDLE) begin
                busy <= 1'b0;
                burst_done <= 1'b0;
                sclk_int <= 1'b0;
            end else if (current_state == START) begin
                busy <= 1'b1;
                burst_count <= {($clog2(BURST_SIZE)){1'b0}};
                bit_count <= DATA_WIDTH-1;
                shift_reg <= tx_data[0];
                burst_done <= 1'b0;
                sclk_int <= 1'b0;
            end else if (current_state == TRANSFER) begin
                sclk_int <= ~sclk_int;
                if (sclk_int == 1'b0) begin // Rising edge
                    shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                    bit_count <= bit_count - 1;
                    if (bit_count == {($clog2(DATA_WIDTH)){1'b0}}) begin
                        if (burst_count == (BURST_SIZE-1)) begin
                            busy <= 1'b0;
                            burst_done <= 1'b1;
                        end else begin
                            burst_count <= burst_count + 1;
                            bit_count <= DATA_WIDTH-1;
                            shift_reg <= tx_data[burst_count + 1];
                        end
                    end
                end else if (sclk_int == 1'b1) begin // Falling edge
                    if (bit_count == (DATA_WIDTH-1)) begin
                        rx_data[burst_count] <= rx_data[burst_count];
                    end else begin
                        rx_data[burst_count][bit_count] <= miso;
                    end
                end
            end
        end
    end

endmodule