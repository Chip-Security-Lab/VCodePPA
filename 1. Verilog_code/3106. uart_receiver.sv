module uart_receiver(
    input wire clk,
    input wire rst,
    input wire rx,
    input wire baud_tick,
    output reg [7:0] data_out,
    output reg data_valid
);
    parameter [2:0] IDLE = 3'b000, START_BIT = 3'b001, 
                    DATA_BITS = 3'b010, STOP_BIT = 3'b011;
    reg [2:0] state, next_state;
    reg [3:0] bit_count;
    reg [3:0] tick_count;
    reg [7:0] rx_shift_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_count <= 0;
            tick_count <= 0;
            data_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    data_valid <= 0;
                    if (rx == 0) // Start bit detected
                        state <= START_BIT;
                end
                START_BIT: begin
                    if (baud_tick) begin
                        if (tick_count == 4'h7) begin // Middle of start bit
                            state <= DATA_BITS;
                            tick_count <= 0;
                            bit_count <= 0;
                        end else
                            tick_count <= tick_count + 1;
                    end
                end
                DATA_BITS: begin
                    if (baud_tick) begin
                        if (tick_count == 4'hF) begin // Sample in middle
                            rx_shift_reg <= {rx, rx_shift_reg[7:1]};
                            tick_count <= 0;
                            if (bit_count == 7)
                                state <= STOP_BIT;
                            else
                                bit_count <= bit_count + 1;
                        end else
                            tick_count <= tick_count + 1;
                    end
                end
                STOP_BIT: begin
                    if (baud_tick) begin
                        if (tick_count == 4'hF) begin
                            data_out <= rx_shift_reg;
                            data_valid <= 1;
                            state <= IDLE;
                        end else
                            tick_count <= tick_count + 1;
                    end
                end
            endcase
        end
    end
endmodule