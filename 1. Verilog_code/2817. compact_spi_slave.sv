module compact_spi_slave(
    input sclk, cs, mosi,
    output miso,
    input [7:0] tx_byte,
    output reg [7:0] rx_byte
);
    reg [7:0] tx_shift;
    reg [2:0] count;
    
    assign miso = tx_shift[7];
    
    always @(posedge sclk or posedge cs) begin
        if (cs) begin
            count <= 3'b000;
            tx_shift <= tx_byte;
        end else begin
            rx_byte <= {rx_byte[6:0], mosi};
            tx_shift <= {tx_shift[6:0], 1'b0};
            count <= count + 1;
        end
    end
endmodule