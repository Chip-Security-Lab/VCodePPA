//SystemVerilog
module MultiResetDetector (
    input wire clk,
    input wire rst_n,
    input wire soft_rst,
    output reg reset_detected
);

    reg async_reset; // Internal signal for asynchronous reset detection

    // Asynchronous Reset Detection Block
    // Handles detection of either rst_n or soft_rst being de-asserted
    always @(*) begin
        if (!rst_n || !soft_rst)
            async_reset = 1'b1;
        else
            async_reset = 1'b0;
    end

    // Synchronous Reset State Update Block
    // Updates reset_detected synchronously on the rising edge of clk
    always @(posedge clk or posedge async_reset) begin
        if (async_reset)
            reset_detected <= 1'b1;
        else
            reset_detected <= 1'b0;
    end

endmodule