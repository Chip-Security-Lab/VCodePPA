//SystemVerilog
module compact_spi_slave(
    input wire        sclk,
    input wire        cs,
    input wire        mosi,
    output wire       miso,
    input wire [7:0]  tx_byte,
    output reg [7:0]  rx_byte
);

    reg [7:0] tx_shift_comb;
    reg [2:0] bit_count_comb;
    reg [7:0] rx_shift_comb;

    reg [7:0] tx_shift_reg;
    reg [2:0] bit_count_reg;
    reg [7:0] rx_shift_reg;

    assign miso = tx_shift_reg[7];

    // Combinational logic moved before registers for retiming
    always @* begin
        if (cs) begin
            bit_count_comb = 3'b000;
            tx_shift_comb  = tx_byte;
            rx_shift_comb  = rx_shift_reg;
        end else begin
            bit_count_comb = bit_count_reg + 1'b1;
            tx_shift_comb  = {tx_shift_reg[6:0], 1'b0};
            rx_shift_comb  = {rx_shift_reg[6:0], mosi};
        end
    end

    // Registers now at outputs of combinational logic
    always @(posedge sclk or posedge cs) begin
        if (cs) begin
            bit_count_reg <= 3'b000;
            tx_shift_reg  <= tx_byte;
            rx_shift_reg  <= rx_shift_reg;
        end else begin
            bit_count_reg <= bit_count_comb;
            tx_shift_reg  <= tx_shift_comb;
            rx_shift_reg  <= rx_shift_comb;
        end
    end

    always @(posedge cs or posedge sclk) begin
        if (cs) begin
            rx_byte <= rx_byte;
        end else begin
            if (bit_count_reg == 3'b111)
                rx_byte <= rx_shift_comb;
            else
                rx_byte <= rx_byte;
        end
    end

endmodule