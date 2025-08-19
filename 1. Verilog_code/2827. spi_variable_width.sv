module spi_variable_width(
    input clk, rst_n,
    input [4:0] data_width, // 1-32 bits
    input [31:0] tx_data,
    input start_tx,
    output reg [31:0] rx_data,
    output reg tx_done,
    
    output sclk,
    output cs_n,
    output mosi,
    input miso
);
    reg [31:0] tx_shift, rx_shift;
    reg [4:0] bit_count;
    reg busy, sclk_r;
    
    assign mosi = tx_shift[31];
    assign sclk = busy ? sclk_r : 1'b0;
    assign cs_n = ~busy;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= 32'd0;
            rx_shift <= 32'd0;
            bit_count <= 5'd0;
            busy <= 1'b0;
            tx_done <= 1'b0;
            sclk_r <= 1'b0;
        end else if (start_tx && !busy) begin
            // Align data to most significant bits
            tx_shift <= tx_data << (32 - data_width);
            rx_shift <= 32'd0;
            bit_count <= data_width;
            busy <= 1'b1;
            tx_done <= 1'b0;
        end else if (busy) begin
            sclk_r <= ~sclk_r;
            
            if (sclk_r) begin // Falling edge
                tx_shift <= {tx_shift[30:0], 1'b0};
                bit_count <= bit_count - 1;
                
                if (bit_count == 1) begin
                    busy <= 1'b0;
                    tx_done <= 1'b1;
                    // Right-align received data
                    rx_data <= (rx_shift << 1 | miso) >> (32 - data_width);
                end
            end else // Rising edge
                rx_shift <= {rx_shift[30:0], miso};
        end else
            tx_done <= 1'b0;
    end
endmodule