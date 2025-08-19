//SystemVerilog
// Top-level module
module async_glitch_filter #(
    parameter GLITCH_THRESHOLD = 3
)(
    input [GLITCH_THRESHOLD-1:0] samples,
    output filtered_out
);
    // Internal signals
    wire [31:0] ones_count;
    
    // Instantiate the submodules
    bit_counter #(
        .WIDTH(GLITCH_THRESHOLD)
    ) u_bit_counter (
        .bits(samples),
        .count(ones_count)
    );
    
    majority_voter #(
        .THRESHOLD(GLITCH_THRESHOLD)
    ) u_majority_voter (
        .count(ones_count),
        .majority_out(filtered_out)
    );
endmodule

// Submodule for counting the number of ones in a bit vector
module bit_counter #(
    parameter WIDTH = 3
)(
    input [WIDTH-1:0] bits,
    output [31:0] count
);
    integer i;
    reg [31:0] ones;
    
    always @(*) begin
        ones = 0;
        i = 0;
        while (i < WIDTH) begin
            ones = ones + bits[i];
            i = i + 1;
        end
    end
    
    assign count = ones;
endmodule

// Submodule for majority voting decision
module majority_voter #(
    parameter THRESHOLD = 3
)(
    input [31:0] count,
    output majority_out
);
    assign majority_out = (count > THRESHOLD/2);
endmodule