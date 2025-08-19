module spi_simple_master(
    input wire clock,
    input wire reset,
    input wire [7:0] mosi_data,
    input wire start,
    output reg [7:0] miso_data,
    output reg done,
    
    // SPI interface
    output reg sck,
    output reg mosi,
    input wire miso,
    output reg ss
);
    localparam IDLE = 2'b00;
    localparam TRANSMIT = 2'b01;
    localparam FINISH = 2'b10;
    
    reg [1:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    always @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'b000;
            shift_reg <= 8'h00;
            miso_data <= 8'h00;
            done <= 1'b0;
            ss <= 1'b1;
            sck <= 1'b0;
            mosi <= 1'b0;
        end else case (state)
            IDLE: if (start) begin
                state <= TRANSMIT;
                shift_reg <= mosi_data;
                ss <= 1'b0;
                bit_count <= 3'b111;
            end
            TRANSMIT: begin
                sck <= ~sck;
                if (sck) begin
                    bit_count <= bit_count - 1;
                    if (bit_count == 0) state <= FINISH;
                    shift_reg <= {shift_reg[6:0], miso};
                end else mosi <= shift_reg[7];
            end
            FINISH: begin
                miso_data <= shift_reg;
                done <= 1'b1;
                ss <= 1'b1;
                state <= IDLE;
            end
        endcase
    end
endmodule