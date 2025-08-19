//SystemVerilog
module IVMU_PrefetchBuf #(parameter DEPTH=2) (
    input clk,
    input [31:0] vec_in,
    output reg [31:0] vec_out
);
    // Internal shift register array
    reg [31:0] buffer [0:DEPTH-1];

    // Buffer register for the input signal vec_in to reduce its fanout load
    reg [31:0] vec_in_buffered;

    // Buffer register for the output of the shift register array (buffer[DEPTH-1])
    // This helps balance the load driving vec_out and can improve timing
    reg [31:0] buffer_output_buffered;

    //------------------------------------------------------------------------
    // Input Buffering Stage
    // Registers the input signal vec_in to reduce its fanout.
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        vec_in_buffered <= vec_in;
    end

    //------------------------------------------------------------------------
    // Shift Register Stage
    // Performs the core shift register operation.
    // Data shifts from buffer[0] to buffer[DEPTH-1].
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        for (int i = DEPTH-1; i > 0; i = i - 1) begin
            buffer[i] <= buffer[i-1];
        end
        // The first element is loaded from the buffered input
        buffer[0] <= vec_in_buffered;
    end

    //------------------------------------------------------------------------
    // Output Buffering Stage
    // Registers the output of the shift register array (buffer[DEPTH-1]).
    // This buffers the signal driving the final output register.
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        buffer_output_buffered <= buffer[DEPTH-1];
    end

    //------------------------------------------------------------------------
    // Final Output Stage
    // Registers the buffered output signal to produce the final output.
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        vec_out <= buffer_output_buffered;
    end

endmodule