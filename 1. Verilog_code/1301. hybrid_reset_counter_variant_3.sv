//SystemVerilog
module hybrid_reset_counter #(
    parameter INIT_VALUE = 4'b1000,
    parameter CLEAR_VALUE = 4'b0001
) (
    input wire clk,       // Clock input
    input wire async_rst, // Asynchronous reset
    input wire sync_clear, // Synchronous clear
    output reg [3:0] data_out // Output data
);

    // Internal signals for retiming
    reg sync_clear_reg;
    reg [3:0] next_data;

    // Register the sync_clear control signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            sync_clear_reg <= 1'b0;
        else
            sync_clear_reg <= sync_clear;
    end

    // Pre-compute the next state combinational logic
    always @(*) begin
        next_data = {data_out[0], data_out[3:1]}; // Circular right shift
    end

    // Main sequential logic with retimed registers
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            data_out <= INIT_VALUE;
        else if (sync_clear_reg)
            data_out <= CLEAR_VALUE;
        else
            data_out <= next_data;
    end

endmodule