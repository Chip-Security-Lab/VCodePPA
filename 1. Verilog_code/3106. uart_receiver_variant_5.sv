//SystemVerilog
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

    // State and Control Signals
    reg [2:0] current_state, next_state;
    reg [3:0] tick_count, bit_count;
    reg rx_sampled;
    reg baud_tick_reg;

    // Shift Register for Data Reception
    reg [7:0] rx_shift_reg;

    // State Transition Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            tick_count <= 0;
            bit_count <= 0;
            rx_sampled <= 1'b1;
            baud_tick_reg <= 1'b0;
            data_out <= 8'h00;
            data_valid <= 1'b0;
            rx_shift_reg <= 8'h00;
        end else begin
            // Update sampled signals
            rx_sampled <= rx;
            baud_tick_reg <= baud_tick;

            // State Transition
            current_state <= next_state;

            // State Logic
            case (current_state)
                IDLE: begin
                    if (rx_sampled == 0)
                        next_state <= START_BIT;
                    else
                        next_state <= IDLE;
                end
                START_BIT: begin
                    if (baud_tick_reg && tick_count == 4'h7)
                        next_state <= DATA_BITS;
                    else
                        next_state <= START_BIT;
                end
                DATA_BITS: begin
                    if (baud_tick_reg && tick_count == 4'hF) begin
                        if (bit_count == 4'h7)
                            next_state <= STOP_BIT;
                        else
                            next_state <= DATA_BITS;
                    end else
                        next_state <= DATA_BITS;
                end
                STOP_BIT: begin
                    if (baud_tick_reg && tick_count == 4'hF) begin
                        next_state <= IDLE;
                        data_out <= rx_shift_reg;
                        data_valid <= 1'b1;
                    end else
                        next_state <= STOP_BIT;
                end
            endcase

            // Tick Count Logic
            if (baud_tick_reg) begin
                if (current_state == START_BIT || current_state == DATA_BITS || current_state == STOP_BIT)
                    tick_count <= tick_count + 1;
                else
                    tick_count <= 0;

                if (current_state == DATA_BITS && tick_count == 4'hF)
                    bit_count <= bit_count + 1;
                else if (current_state == START_BIT)
                    bit_count <= 0;
            end
            
            // Data Sampling Logic
            if (current_state == DATA_BITS && baud_tick_reg && tick_count == 4'hF) begin
                rx_shift_reg <= {rx_sampled, rx_shift_reg[7:1]};
            end else if (current_state == STOP_BIT) begin
                data_valid <= 1'b0; // Reset data valid after output
            end
        end
    end
endmodule