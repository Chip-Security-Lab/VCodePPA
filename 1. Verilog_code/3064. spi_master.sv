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
    reg [1:0] state, next;
    reg [7:0] tx_shift, rx_shift;
    reg [3:0] bit_cnt;
    reg [2:0] clk_cnt;
    
    always @(posedge clk or posedge rst)
        if (rst) begin
            state <= IDLE;
            clk_cnt <= 0;
            bit_cnt <= 0;
            sclk <= 1'b0;
            cs_n <= 1'b1;
        end else begin
            state <= next;
            if (state == IDLE) begin
                if (tx_valid) begin
                    tx_shift <= tx_data;
                    cs_n <= 1'b0;
                end
            end else begin
                clk_cnt <= clk_cnt + 1;
                if (clk_cnt == CLK_DIV-1) begin
                    clk_cnt <= 0;
                    if (state == SETUP) sclk <= 1'b1;
                    else if (state == SAMPLE) begin
                        sclk <= 1'b0;
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                
                if (state == SETUP)
                    mosi <= tx_shift[7];
                else if (state == SAMPLE && clk_cnt == 0) begin
                    tx_shift <= {tx_shift[6:0], 1'b0};
                    rx_shift <= {rx_shift[6:0], miso};
                end
                
                if (state == DONE) begin
                    cs_n <= 1'b1;
                    rx_data <= rx_shift;
                    rx_valid <= 1'b1;
                end else rx_valid <= 1'b0;
            end
        end
    
    always @(*)
        case (state)
            IDLE: next = tx_valid ? SETUP : IDLE;
            SETUP: next = (clk_cnt == CLK_DIV-1) ? SAMPLE : SETUP;
            SAMPLE: next = (clk_cnt == CLK_DIV-1) ? 
                        (bit_cnt == 4'd7) ? DONE : SETUP : SAMPLE;
            DONE: next = IDLE;
        endcase
endmodule