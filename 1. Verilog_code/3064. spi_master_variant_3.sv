//SystemVerilog
module spi_master #(
    parameter CLK_DIV = 4
)(
    input wire clk, rst,
    input wire [7:0] tx_data,
    input wire tx_valid,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg sclk, cs_n, mosi,
    input wire miso
);

    localparam IDLE=2'b00, SETUP=2'b01, SAMPLE=2'b10, DONE=2'b11;
    reg [1:0] state, next_state;
    reg [7:0] tx_shift, rx_shift;
    reg [3:0] bit_cnt;
    reg [2:0] clk_cnt;
    wire [7:0] tx_shift_next;
    
    // Two's complement addition for subtraction
    assign tx_shift_next = {tx_shift[6:0], 1'b0} + 8'h00;
    
    // Combinational logic for next state
    always @(*) begin
        case (state)
            IDLE:   next_state = tx_valid ? SETUP : IDLE;
            SETUP:  next_state = (clk_cnt == CLK_DIV-1) ? SAMPLE : SETUP;
            SAMPLE: next_state = (clk_cnt == CLK_DIV-1) ? 
                               (bit_cnt == 4'd7) ? DONE : SETUP : SAMPLE;
            DONE:   next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= 0;
            bit_cnt <= 0;
            sclk <= 1'b0;
            cs_n <= 1'b1;
            rx_valid <= 1'b0;
        end else begin
            state <= next_state;
            
            if (state != IDLE) begin
                clk_cnt <= (clk_cnt == CLK_DIV-1) ? 0 : clk_cnt + 1;
            end

            if (state == SETUP && clk_cnt == CLK_DIV-1) begin
                sclk <= 1'b1;
            end else if (state == SAMPLE && clk_cnt == CLK_DIV-1) begin
                sclk <= 1'b0;
            end

            if (state == SAMPLE && clk_cnt == 0) begin
                bit_cnt <= bit_cnt + 1;
                tx_shift <= tx_shift_next;
                rx_shift <= {rx_shift[6:0], miso};
            end

            if (state == IDLE && tx_valid) begin
                tx_shift <= tx_data;
                cs_n <= 1'b0;
            end else if (state == DONE) begin
                cs_n <= 1'b1;
                rx_data <= rx_shift;
                rx_valid <= 1'b1;
            end else begin
                rx_valid <= 1'b0;
            end
        end
    end

    always @(*) begin
        if (state == SETUP) begin
            mosi = tx_shift[7];
        end else begin
            mosi = 1'b0;
        end
    end

endmodule