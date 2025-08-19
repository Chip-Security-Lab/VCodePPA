//SystemVerilog
module i2c_slave_interrupt(
    input  wire        clk,
    input  wire        reset,
    input  wire [6:0]  device_addr,
    output reg  [7:0]  data_out,
    output reg         data_ready,
    output reg         addr_match_int,
    output reg         data_int,
    output reg         error_int,
    inout              sda,
    inout              scl
);

    reg  [3:0] bit_count;
    reg  [2:0] state;
    reg  [7:0] rx_shift_reg;
    reg        sda_in_r, scl_in_r, sda_out;

    // Pre-capture SDA/SCL values for next cycle
    wire       sda_in  = sda;
    wire       scl_in  = scl;

    // Path-balanced start/stop condition detection
    wire sda_rising_edge   = ~sda_in_r & sda_in;
    wire sda_falling_edge  = sda_in_r & ~sda_in;
    wire scl_high          = scl_in_r & scl_in;

    wire start_condition   = scl_high & sda_falling_edge;
    wire stop_condition    = scl_high & sda_rising_edge;

    // Input sampling and output assignment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_in_r    <= 1'b1;
            scl_in_r    <= 1'b1;
        end else begin
            sda_in_r    <= sda_in;
            scl_in_r    <= scl_in;
        end
    end

    // State Machine with path-balanced logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= 3'b000;
            data_int        <= 1'b0;
            data_ready      <= 1'b0;
            addr_match_int  <= 1'b0;
            error_int       <= 1'b0;
            data_out        <= 8'b0;
            bit_count       <= 4'b0;
            rx_shift_reg    <= 8'b0;
        end else begin
            // Clear interrupts by default, assert only as needed
            data_int        <= 1'b0;
            addr_match_int  <= 1'b0;
            error_int       <= 1'b0;
            data_ready      <= 1'b0;

            case (state)
                3'b000: begin
                    if (start_condition) begin
                        state       <= 3'b001;
                        bit_count   <= 4'b0;
                        rx_shift_reg<= 8'b0;
                    end
                end

                3'b001: begin
                    // Example: receive bits (expand as needed)
                    if (bit_count < 4'd8) begin
                        rx_shift_reg    <= {rx_shift_reg[6:0], sda_in};
                        bit_count       <= bit_count + 1'b1;
                    end else begin
                        state           <= 3'b010;
                    end
                end

                3'b010: begin
                    // Address match check
                    if (rx_shift_reg[7:1] == device_addr) begin
                        addr_match_int  <= 1'b1;
                        state           <= 3'b011;
                    end else begin
                        error_int       <= 1'b1;
                        state           <= 3'b000;
                    end
                end

                3'b011: begin
                    data_out        <= rx_shift_reg;
                    data_int        <= 1'b1;
                    data_ready      <= 1'b1;
                    state           <= 3'b000;
                end

                default: begin
                    state           <= 3'b000;
                end
            endcase

            // Stop condition resets state
            if (stop_condition) begin
                state           <= 3'b000;
                bit_count       <= 4'b0;
            end
        end
    end

endmodule