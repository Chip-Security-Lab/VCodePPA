//SystemVerilog
module uart_receiver(
    input wire clk,
    input wire rst,
    input wire rx,
    input wire baud_tick,
    output reg [7:0] data_out,
    output reg data_valid
);
    parameter [2:0] IDLE = 3'b000, 
                    START_BIT = 3'b001, 
                    DATA_BITS = 3'b010, 
                    STOP_BIT = 3'b011;
    
    reg [2:0] state, next_state;
    reg [3:0] tick_count;
    reg rx_sampled;
    reg [3:0] bit_count;
    reg [7:0] rx_shift_reg;
    
    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tick_count <= 0;
            rx_sampled <= 1;
            bit_count <= 0;
            rx_shift_reg <= 0;
            data_out <= 0;
            data_valid <= 0;
        end else begin
            rx_sampled <= rx;
            data_valid <= 0;
            
            case (state)
                IDLE: begin
                    if (!rx_sampled) begin
                        state <= START_BIT;
                        tick_count <= 0;
                    end
                end
                START_BIT: begin
                    if (baud_tick) begin
                        tick_count <= tick_count + 1;
                        if (tick_count == 4'h7) begin
                            state <= DATA_BITS;
                            tick_count <= 0;
                            bit_count <= 0;
                        end
                    end
                end
                DATA_BITS: begin
                    if (baud_tick) begin
                        tick_count <= tick_count + 1;
                        if (tick_count == 4'hF) begin
                            tick_count <= 0;
                            rx_shift_reg <= {rx_sampled, rx_shift_reg[7:1]};
                            if (bit_count == 7) begin
                                state <= STOP_BIT;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end
                    end
                end
                STOP_BIT: begin
                    if (baud_tick) begin
                        tick_count <= tick_count + 1;
                        if (tick_count == 4'hF) begin
                            state <= IDLE;
                            data_out <= rx_shift_reg;
                            data_valid <= 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule