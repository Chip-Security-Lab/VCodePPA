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

    // State registers and data path
    reg [2:0] state_comb;
    reg [2:0] state_pipe1, state_reg;
    reg [7:0] data_buf_comb;
    reg [7:0] data_buf_pipe1, data_buf_reg;
    reg [3:0] bit_count_comb;
    reg [3:0] bit_count_pipe1, bit_count_reg;
    reg data_valid_comb, data_valid_pipe1, data_valid_reg;
    reg prev_sda_reg, prev_scl_reg;
    reg prev_sda_comb, prev_scl_comb;
    reg framing_error_comb, framing_error_pipe1, framing_error_reg;
    reg overrun_error_comb, overrun_error_pipe1, overrun_error_reg;
    reg addr_error_comb, addr_error_pipe1, addr_error_reg;
    reg [7:0] rx_data_comb, rx_data_pipe1, rx_data_reg;

    // Pipeline stage 1: Break up long combinational path
    always @(*) begin
        // Combination logic for all outputs and states
        prev_sda_comb = sda;
        prev_scl_comb = scl;
        state_comb = state_reg;
        data_buf_comb = data_buf_reg;
        bit_count_comb = bit_count_reg;
        data_valid_comb = data_valid_reg;
        framing_error_comb = framing_error_reg;
        overrun_error_comb = overrun_error_reg;
        addr_error_comb = addr_error_reg;
        rx_data_comb = rx_data_reg;

        // Framing error logic (critical path candidate)
        if (state_reg == 3'b010 && bit_count_reg > 4'd8)
            framing_error_comb = 1'b1;
        else if (!rst_n)
            framing_error_comb = 1'b0;
    end

    // Pipeline register: stage 1
    always @(posedge scl or negedge rst_n) begin
        if (!rst_n) begin
            state_pipe1 <= 3'b000;
            data_buf_pipe1 <= 8'b0;
            bit_count_pipe1 <= 4'b0;
            data_valid_pipe1 <= 1'b0;
            framing_error_pipe1 <= 1'b0;
            overrun_error_pipe1 <= 1'b0;
            addr_error_pipe1 <= 1'b0;
            rx_data_pipe1 <= 8'b0;
        end else begin
            state_pipe1 <= state_comb;
            data_buf_pipe1 <= data_buf_comb;
            bit_count_pipe1 <= bit_count_comb;
            data_valid_pipe1 <= data_valid_comb;
            framing_error_pipe1 <= framing_error_comb;
            overrun_error_pipe1 <= overrun_error_comb;
            addr_error_pipe1 <= addr_error_comb;
            rx_data_pipe1 <= rx_data_comb;
        end
    end

    // Pipeline stage 2: Registers after pipeline stage 1
    always @(posedge scl or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= 3'b000;
            data_buf_reg <= 8'b0;
            bit_count_reg <= 4'b0;
            data_valid_reg <= 1'b0;
            prev_sda_reg <= 1'b1;
            prev_scl_reg <= 1'b1;
            framing_error_reg <= 1'b0;
            overrun_error_reg <= 1'b0;
            addr_error_reg <= 1'b0;
            rx_data_reg <= 8'b0;
        end else begin
            state_reg <= state_pipe1;
            data_buf_reg <= data_buf_pipe1;
            bit_count_reg <= bit_count_pipe1;
            data_valid_reg <= data_valid_pipe1;
            prev_sda_reg <= prev_sda_comb;
            prev_scl_reg <= prev_scl_comb;
            framing_error_reg <= framing_error_pipe1;
            overrun_error_reg <= overrun_error_pipe1;
            addr_error_reg <= addr_error_pipe1;
            rx_data_reg <= rx_data_pipe1;
        end
    end

    // Output assignments from retimed registers
    always @(*) begin
        rx_data = rx_data_reg;
        framing_error = framing_error_reg;
        overrun_error = overrun_error_reg;
        addr_error = addr_error_reg;
    end

    // Start/Stop condition logic using retimed prev_sda_reg/prev_scl_reg
    wire start_cond = prev_sda_reg & ~sda & scl;
    wire stop_cond = ~prev_sda_reg & sda & scl;

endmodule