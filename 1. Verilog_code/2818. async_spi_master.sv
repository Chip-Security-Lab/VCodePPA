module async_spi_master(
    input clk, rst,
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
    reg [15:0] shift_reg;
    reg [4:0] bit_cnt;
    reg running, sck_r;
    
    assign mosi = shift_reg[15];
    assign data_out = shift_reg;
    assign xfer_done = ~running;
    assign ss_n = ~running;
    assign sck = running ? sck_r : 1'b0;
    
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 16'd0;
            bit_cnt <= 5'd0;
            running <= 1'b0;
            sck_r <= 1'b0;
        end else if (!running && begin_xfer) begin
            shift_reg <= data_in;
            bit_cnt <= 5'd16;
            running <= 1'b1;
        end else if (running) begin
            sck_r <= ~sck_r;
            if (sck_r) begin // falling edge
                if (bit_cnt == 0) running <= 1'b0;
                else bit_cnt <= bit_cnt - 5'd1;
            end else begin // rising edge
                shift_reg <= {shift_reg[14:0], miso};
            end
        end
    end
endmodule