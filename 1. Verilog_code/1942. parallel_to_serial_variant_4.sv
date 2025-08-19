//SystemVerilog
module parallel_to_serial #(
    parameter DATA_WIDTH = 8
)(
    input wire clock,
    input wire reset,
    input wire load,
    input wire [DATA_WIDTH-1:0] parallel_data,
    output wire serial_out,
    output wire tx_done
);

    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_counter_reg; // Main bit counter register
    reg [$clog2(DATA_WIDTH):0] bit_counter_buf1; // First stage buffer
    reg [$clog2(DATA_WIDTH):0] bit_counter_buf2; // Second stage buffer

    //-----------------------------------------------------------------------------
    // Shift Register Logic: Handles loading and shifting of parallel data
    //-----------------------------------------------------------------------------
    always @(posedge clock) begin
        if (reset) begin
            shift_reg <= {DATA_WIDTH{1'b0}};
        end else if (load) begin
            shift_reg <= parallel_data;
        end else if (bit_counter_buf2 < DATA_WIDTH && bit_counter_buf2 != 0) begin
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
        end
    end

    //-----------------------------------------------------------------------------
    // Bit Counter Logic: Handles counting transmitted bits and load/reset conditions
    //-----------------------------------------------------------------------------
    always @(posedge clock) begin
        if (reset) begin
            bit_counter_reg <= DATA_WIDTH;
        end else if (load) begin
            bit_counter_reg <= 0;
        end else if (bit_counter_reg < DATA_WIDTH) begin
            bit_counter_reg <= bit_counter_reg + 1'b1;
        end
    end

    //-----------------------------------------------------------------------------
    // Bit Counter Buffering Stages for Fanout Reduction and Timing Balance
    //-----------------------------------------------------------------------------
    always @(posedge clock) begin
        if (reset) begin
            bit_counter_buf1 <= DATA_WIDTH;
            bit_counter_buf2 <= DATA_WIDTH;
        end else begin
            bit_counter_buf1 <= bit_counter_reg;
            bit_counter_buf2 <= bit_counter_buf1;
        end
    end

    //-----------------------------------------------------------------------------
    // Serial Output Assignment: Always outputs the MSB of the shift register
    //-----------------------------------------------------------------------------
    assign serial_out = shift_reg[DATA_WIDTH-1];

    //-----------------------------------------------------------------------------
    // Transmission Done Flag: Indicates when all bits have been transmitted
    //-----------------------------------------------------------------------------
    assign tx_done = (bit_counter_buf2 == DATA_WIDTH);

endmodule