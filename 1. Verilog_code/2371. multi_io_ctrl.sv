module multi_io_ctrl (
    input clk, mode_sel,
    input [7:0] data_in,
    output reg scl, sda, spi_cs
);
always @(posedge clk) begin
    if (mode_sel) begin // I2C mode
        scl <= ~scl;
        sda <= data_in[7];
    end else begin      // SPI mode
        spi_cs <= data_in[0];
    end
end
endmodule
