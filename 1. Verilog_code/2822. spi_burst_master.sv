module spi_burst_master #(
    parameter DATA_WIDTH = 8,
    parameter BURST_SIZE = 4
)(
    input clk, rst_n,
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
    reg busy, sclk_int;
    
    assign sclk = busy ? sclk_int : 1'b0;
    assign cs_n = ~busy;
    assign mosi = shift_reg[DATA_WIDTH-1];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            burst_done <= 1'b0;
            bit_count <= 0;
            burst_count <= 0;
            sclk_int <= 1'b0;
        end else if (burst_start && !busy) begin
            busy <= 1'b1;
            burst_count <= 0;
            bit_count <= DATA_WIDTH-1;
            shift_reg <= tx_data[0];
            burst_done <= 1'b0;
        end else if (busy) begin
            sclk_int <= ~sclk_int;
            if (!sclk_int) begin // Rising edge
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                bit_count <= bit_count - 1;
                
                if (bit_count == 0) begin
                    if (burst_count == BURST_SIZE-1) begin
                        busy <= 1'b0;
                        burst_done <= 1'b1;
                    end else begin
                        burst_count <= burst_count + 1;
                        bit_count <= DATA_WIDTH-1;
                        shift_reg <= tx_data[burst_count+1];
                    end
                end
            end else begin // Falling edge
                if (bit_count == DATA_WIDTH-1)
                    rx_data[burst_count] <= rx_data[burst_count];
                else
                    rx_data[burst_count][bit_count] <= miso;
            end
        end
    end
endmodule