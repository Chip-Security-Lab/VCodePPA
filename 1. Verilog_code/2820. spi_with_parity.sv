module spi_with_parity(
    input clk, rst_n,
    input [7:0] tx_data,
    input tx_start,
    output [7:0] rx_data,
    output rx_done,
    output parity_error,
    
    output sclk,
    output ss_n,
    output mosi,
    input miso
);
    reg [8:0] tx_shift; // 8 data bits + 1 parity bit
    reg [8:0] rx_shift;
    reg [3:0] bit_count;
    reg busy, done_r;
    reg sclk_r;
    
    wire tx_parity = ^tx_data; // Calculated parity bit
    
    assign sclk = busy ? sclk_r : 1'b0;
    assign ss_n = ~busy;
    assign mosi = tx_shift[8];
    assign rx_data = rx_shift[7:0];
    assign rx_done = done_r;
    assign parity_error = done_r & (^rx_shift[7:0] != rx_shift[8]);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= 9'h000;
            rx_shift <= 9'h000;
            bit_count <= 4'h0;
            busy <= 1'b0;
            done_r <= 1'b0;
            sclk_r <= 1'b0;
        end else if (tx_start && !busy) begin
            tx_shift <= {tx_data, tx_parity};
            bit_count <= 4'd9; // 8 data bits + 1 parity
            busy <= 1'b1;
            done_r <= 1'b0;
        end else if (busy) begin
            sclk_r <= ~sclk_r;
            if (sclk_r) begin // Falling edge
                tx_shift <= {tx_shift[7:0], 1'b0};
                if (bit_count == 4'd0) begin
                    busy <= 1'b0;
                    done_r <= 1'b1;
                end
            end else begin // Rising edge
                rx_shift <= {rx_shift[7:0], miso};
                bit_count <= bit_count - 4'd1;
            end
        end
    end
endmodule