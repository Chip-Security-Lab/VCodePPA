//SystemVerilog
module uart_receiver(
    input wire clk,
    input wire rst,
    input wire rx,
    input wire baud_tick,
    output reg [7:0] data_out,
    output reg data_req,
    input wire data_ack
);
    parameter [2:0] IDLE = 3'b000, START_BIT = 3'b001, 
                    DATA_BITS = 3'b010, STOP_BIT = 3'b011;
    reg [2:0] state, next_state;
    reg [3:0] bit_count;
    reg [3:0] tick_count;
    reg [7:0] rx_shift_reg;
    reg req_pending;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_count <= 0;
            tick_count <= 0;
            data_req <= 0;
            req_pending <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (req_pending && data_ack) begin
                        data_req <= 0;
                        req_pending <= 0;
                    end
                    if (!rx) // Start bit detected
                        state <= START_BIT;
                end
                START_BIT: begin
                    if (baud_tick && tick_count == 4'h7) begin // Middle of start bit
                        state <= DATA_BITS;
                        tick_count <= 0;
                        bit_count <= 0;
                    end else if (baud_tick) begin
                        tick_count <= tick_count + 1;
                    end
                end
                DATA_BITS: begin
                    if (baud_tick) begin
                        if (tick_count == 4'hF) begin // Sample in middle
                            rx_shift_reg <= {rx, rx_shift_reg[7:1]};
                            tick_count <= 0;
                            if (bit_count == 4'd7) // Check bit count
                                state <= STOP_BIT;
                            else
                                bit_count <= bit_count + 1;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end
                STOP_BIT: begin
                    if (baud_tick && tick_count == 4'hF) begin
                        data_out <= rx_shift_reg;
                        data_req <= 1;
                        req_pending <= 1;
                        state <= IDLE;
                    end else if (baud_tick) begin
                        tick_count <= tick_count + 1;
                    end
                end
            endcase
        end
    end
endmodule