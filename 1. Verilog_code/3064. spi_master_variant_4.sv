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
    reg [1:0] state, next;
    reg [7:0] tx_shift, rx_shift;
    reg [3:0] bit_cnt;
    reg [2:0] clk_cnt;
    
    // State transition logic
    always @(*)
        case (state)
            IDLE: next = tx_valid ? SETUP : IDLE;
            SETUP: next = (clk_cnt == CLK_DIV-1) ? SAMPLE : SETUP;
            SAMPLE: next = (clk_cnt == CLK_DIV-1) ? 
                        (bit_cnt == 4'd7) ? DONE : SETUP : SAMPLE;
            DONE: next = IDLE;
        endcase
    
    // Main control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= 0;
            bit_cnt <= 0;
            sclk <= 1'b0;
            cs_n <= 1'b1;
            rx_valid <= 1'b0;
            mosi <= 1'b0;
        end else begin
            state <= next;
            
            // Default values
            rx_valid <= 1'b0;
            
            // Clock counter logic
            if (state != IDLE) begin
                clk_cnt <= (clk_cnt == CLK_DIV-1) ? 0 : clk_cnt + 1;
            end
            
            // State-specific logic
            if (state == IDLE && tx_valid) begin
                tx_shift <= tx_data;
                cs_n <= 1'b0;
            end
            
            if (state == SETUP) begin
                mosi <= tx_shift[7];
                sclk <= (clk_cnt == CLK_DIV-1) ? 1'b1 : sclk;
            end
            
            if (state == SAMPLE && clk_cnt == CLK_DIV-1) begin
                sclk <= 1'b0;
                bit_cnt <= bit_cnt + 1;
                tx_shift <= {tx_shift[6:0], 1'b0};
                rx_shift <= {rx_shift[6:0], miso};
            end
            
            if (state == DONE) begin
                cs_n <= 1'b1;
                rx_data <= rx_shift;
                rx_valid <= 1'b1;
            end
        end
    end
endmodule