//SystemVerilog
module i2c_error_slave #(
    parameter ADDR_WIDTH = 7
)(
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] device_addr,
    output reg [7:0] rx_data,
    output reg framing_error,
    output reg overrun_error,
    output reg addr_error,
    inout wire scl,
    inout wire sda
);
    // State and data registers
    reg [2:0] curr_state, next_state;
    reg [7:0] curr_data_buf, next_data_buf;
    reg [3:0] curr_bit_count, next_bit_count;
    reg curr_data_valid, next_data_valid;
    reg prev_sda_reg, next_prev_sda;
    reg prev_scl_reg, next_prev_scl;
    reg curr_framing_error, next_framing_error;
    reg curr_overrun_error, next_overrun_error;
    reg curr_addr_error, next_addr_error;
    reg [7:0] curr_rx_data, next_rx_data;

    // Intermediate signals for control flow clarity
    wire is_start_condition;
    wire is_stop_condition;
    wire is_state_data;
    wire is_bit_count_overflow;

    // Assignments for I2C start/stop detection
    assign is_start_condition = prev_sda_reg & ~sda & scl;
    assign is_stop_condition  = ~prev_sda_reg & sda & scl;
    assign is_state_data = (curr_state == 3'b010);
    assign is_bit_count_overflow = (curr_bit_count > 4'd8);

    // Combinational logic for next state and outputs
    always @* begin
        // Default assignments
        next_state          = curr_state;
        next_data_buf       = curr_data_buf;
        next_bit_count      = curr_bit_count;
        next_data_valid     = curr_data_valid;
        next_prev_sda       = sda;
        next_prev_scl       = scl;
        next_framing_error  = curr_framing_error;
        next_overrun_error  = curr_overrun_error;
        next_addr_error     = curr_addr_error;
        next_rx_data        = curr_rx_data;

        // Reset condition
        if (!rst_n) begin
            next_state          = 3'b000;
            next_data_buf       = 8'b00000000;
            next_bit_count      = 4'b0000;
            next_data_valid     = 1'b0;
            next_framing_error  = 1'b0;
            next_overrun_error  = 1'b0;
            next_addr_error     = 1'b0;
            next_rx_data        = 8'b00000000;
        end else begin
            // Error detection logic (decomposed conditions)
            if (is_state_data) begin
                if (is_bit_count_overflow) begin
                    next_framing_error = 1'b1;
                end
            end
            // Expand this block for additional error logic as needed
        end
    end

    // Sequential logic (registers update on clock or reset)
    always @(posedge scl or negedge rst_n) begin
        if (!rst_n) begin
            curr_state          <= 3'b000;
            curr_data_buf       <= 8'b00000000;
            curr_bit_count      <= 4'b0000;
            curr_data_valid     <= 1'b0;
            prev_sda_reg        <= 1'b1;
            prev_scl_reg        <= 1'b1;
            curr_framing_error  <= 1'b0;
            curr_overrun_error  <= 1'b0;
            curr_addr_error     <= 1'b0;
            curr_rx_data        <= 8'b00000000;
        end else begin
            curr_state          <= next_state;
            curr_data_buf       <= next_data_buf;
            curr_bit_count      <= next_bit_count;
            curr_data_valid     <= next_data_valid;
            prev_sda_reg        <= next_prev_sda;
            prev_scl_reg        <= next_prev_scl;
            curr_framing_error  <= next_framing_error;
            curr_overrun_error  <= next_overrun_error;
            curr_addr_error     <= next_addr_error;
            curr_rx_data        <= next_rx_data;
        end
    end

    // Output logic
    always @(*) begin
        rx_data         = curr_rx_data;
        framing_error   = curr_framing_error;
        overrun_error   = curr_overrun_error;
        addr_error      = curr_addr_error;
    end

endmodule