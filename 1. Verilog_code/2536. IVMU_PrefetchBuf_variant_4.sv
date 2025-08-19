//SystemVerilog
module IVMU_PrefetchBuf #(parameter DEPTH=2) (
    input clk,
    input [31:0] vec_in,
    output reg [31:0] vec_out
);
    // Internal shift register buffer
    reg [31:0] buffer [0:DEPTH-1];

    // Buffer register for the input signal vec_in to reduce its fanout load on external logic
    // This adds a pipeline stage for vec_in
    reg [31:0] vec_in_buffered;

    // Buffer register for the signal coming out of the shift register (buffer[DEPTH-1])
    // This helps reduce the fanout load of buffer[DEPTH-1] on the final output stage
    // This adds another pipeline stage before the final output
    reg [31:0] buffer_out_buffered;

    always @(posedge clk) begin
        // Pipeline stage 1: Buffer the input signal
        vec_in_buffered <= vec_in;

        // Pipeline stage 2 to DEPTH+1: Shift the buffer contents
        // The loop describes the structure; synthesis will unroll it.
        // The output of each buffer element buffer[i-1] drives only one input buffer[i],
        // except for buffer[DEPTH-1] which drives buffer_out_buffered.
        for (integer i = DEPTH-1; i > 0; i = i - 1) begin
            buffer[i] <= buffer[i-1];
        end

        // Load the buffered input into the first element of the buffer array
        buffer[0] <= vec_in_buffered;

        // Pipeline stage DEPTH+2: Buffer the signal from the last element buffer[DEPTH-1]
        // This specifically buffers the output of the shift register array.
        buffer_out_buffered <= buffer[DEPTH-1];

        // Pipeline stage DEPTH+3: Assign the buffered signal to the final output register
        // This ensures the output vec_out is also registered, driven by the buffered signal.
        vec_out <= buffer_out_buffered;
    end

endmodule