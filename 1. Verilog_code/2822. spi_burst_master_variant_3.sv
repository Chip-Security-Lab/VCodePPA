//SystemVerilog
module spi_burst_master #(
    parameter DATA_WIDTH = 8,
    parameter BURST_SIZE = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] tx_data [0:BURST_SIZE-1],
    input wire burst_start,
    output reg [DATA_WIDTH-1:0] rx_data [0:BURST_SIZE-1],
    output reg burst_done,

    output wire sclk,
    output wire cs_n,
    output wire mosi,
    input wire miso
);

    // Internal signals and registers
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH)-1:0] bit_index;
    reg [$clog2(BURST_SIZE)-1:0] burst_index;
    reg busy_flag, sclk_reg;

    assign sclk = busy_flag ? sclk_reg : 1'b0;
    assign cs_n = ~busy_flag;
    assign mosi = shift_reg[DATA_WIDTH-1];

    // Optimized comparison logic using range checks
    wire is_last_bit    = (bit_index == 0);
    wire is_last_burst  = (burst_index == (BURST_SIZE-1));
    wire is_valid_bit   = (bit_index < DATA_WIDTH);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_flag   <= 1'b0;
            burst_done  <= 1'b0;
            bit_index   <= {($clog2(DATA_WIDTH)){1'b0}};
            burst_index <= {($clog2(BURST_SIZE)){1'b0}};
            sclk_reg    <= 1'b0;
        end else if (burst_start && !busy_flag) begin
            busy_flag   <= 1'b1;
            burst_index <= {($clog2(BURST_SIZE)){1'b0}};
            bit_index   <= DATA_WIDTH-1;
            shift_reg   <= tx_data[0];
            burst_done  <= 1'b0;
        end else if (busy_flag) begin
            sclk_reg <= ~sclk_reg;
            if (!sclk_reg) begin // Rising edge
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                if (bit_index > 0) begin
                    bit_index <= bit_index - 1'b1;
                end else begin
                    if (burst_index == (BURST_SIZE-1)) begin
                        busy_flag  <= 1'b0;
                        burst_done <= 1'b1;
                    end else begin
                        burst_index <= burst_index + 1'b1;
                        bit_index   <= DATA_WIDTH-1;
                        shift_reg   <= tx_data[burst_index + 1'b1];
                    end
                end
            end else begin // Falling edge
                if (is_valid_bit)
                    rx_data[burst_index][bit_index] <= miso;
            end
        end
    end

endmodule