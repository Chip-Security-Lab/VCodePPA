module usb_sie(
    input clk, reset_n,
    input [7:0] rx_data,
    input rx_valid,
    output reg rx_ready,
    output reg [7:0] tx_data,
    output reg tx_valid,
    input tx_ready,
    output reg [1:0] state
);
    localparam IDLE = 2'b00, RX = 2'b01, PROCESS = 2'b10, TX = 2'b11;
    reg [7:0] buffer;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            rx_ready <= 1'b0;
            tx_valid <= 1'b0;
            tx_data <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    if (rx_valid) begin
                        rx_ready <= 1'b1;
                        state <= RX;
                    end
                end
                RX: begin
                    buffer <= rx_data;
                    rx_ready <= 1'b0;
                    state <= PROCESS;
                end
                PROCESS: begin
                    tx_data <= buffer;
                    tx_valid <= 1'b1;
                    state <= TX;
                end
                TX: begin
                    if (tx_ready) begin
                        tx_valid <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule