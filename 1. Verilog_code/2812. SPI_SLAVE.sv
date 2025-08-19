module SPI_SLAVE #(parameter WIDTH = 8) (
    input wire i_Clk,
    input wire i_SPI_CS_n,
    input wire i_SPI_Clk,
    input wire i_SPI_MOSI,
    output wire o_SPI_MISO,
    input wire [WIDTH-1:0] i_TX_Byte,
    output reg [WIDTH-1:0] o_RX_Byte,
    output reg o_RX_Done
);
    reg [2:0] r_SPI_Clk_Count;
    reg [WIDTH-1:0] r_Shift_Reg;
    
    // MISO output is MSB of shift register
    assign o_SPI_MISO = r_Shift_Reg[WIDTH-1];
    
    always @(posedge i_Clk) begin
        if (i_SPI_CS_n) begin
            r_SPI_Clk_Count <= 0;
            o_RX_Done <= 1'b0;
        end else begin
            // Detect rising edge on SPI Clock
            if (i_SPI_Clk && !r_SPI_Clk_Count[0]) begin
                r_Shift_Reg <= {r_Shift_Reg[WIDTH-2:0], i_SPI_MOSI};
                r_SPI_Clk_Count[0] <= 1'b1;
                if (r_SPI_Clk_Count[2:1] == WIDTH-1) begin
                    o_RX_Byte <= {r_Shift_Reg[WIDTH-2:0], i_SPI_MOSI};
                    o_RX_Done <= 1'b1;
                    r_SPI_Clk_Count[2:1] <= 0;
                end else r_SPI_Clk_Count[2:1] <= r_SPI_Clk_Count[2:1] + 1;
            end else if (!i_SPI_Clk) r_SPI_Clk_Count[0] <= 1'b0;
        end
    end
endmodule