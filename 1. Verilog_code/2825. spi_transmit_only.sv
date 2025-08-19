module spi_transmit_only(
    input clk, reset,
    input [15:0] tx_data,
    input tx_start,
    output reg tx_busy,
    output reg tx_done,
    
    output spi_clk,
    output spi_cs_n,
    output spi_mosi
);
    localparam IDLE = 2'b00;
    localparam TRANSMIT = 2'b01;
    localparam FINISH = 2'b10;
    
    reg [1:0] state;
    reg [3:0] bit_count;
    reg [15:0] shift_reg;
    reg spi_clk_int;
    
    assign spi_mosi = shift_reg[15];
    assign spi_clk = (state == TRANSMIT) ? spi_clk_int : 1'b0;
    assign spi_cs_n = (state == IDLE || state == FINISH);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 4'd0;
            shift_reg <= 16'd0;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            spi_clk_int <= 1'b0;
        end else case (state)
            IDLE: begin
                tx_done <= 1'b0;
                if (tx_start) begin
                    shift_reg <= tx_data;
                    bit_count <= 4'd15;
                    tx_busy <= 1'b1;
                    state <= TRANSMIT;
                end
            end
            TRANSMIT: begin
                spi_clk_int <= ~spi_clk_int;
                if (!spi_clk_int) begin // falling edge
                    if (bit_count == 0) 
                        state <= FINISH;
                    else begin
                        bit_count <= bit_count - 1;
                        shift_reg <= {shift_reg[14:0], 1'b0};
                    end
                end
            end
            FINISH: begin
                tx_busy <= 1'b0;
                tx_done <= 1'b1;
                state <= IDLE;
            end
        endcase
    end
endmodule