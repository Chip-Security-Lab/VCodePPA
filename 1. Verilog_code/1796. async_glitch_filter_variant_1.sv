//SystemVerilog
// Counter module for counting ones
module ones_counter #(
    parameter WIDTH = 3
)(
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH+1)-1:0] count_out
);
    always @(*) begin
        count_out = 0;
        for (int i = 0; i < WIDTH; i++) begin
            count_out = count_out + data_in[i];
        end
    end
endmodule

// Majority voting module
module majority_voter #(
    parameter WIDTH = 3
)(
    input [$clog2(WIDTH+1)-1:0] count_in,
    output reg decision_out
);
    always @(*) begin
        decision_out = (count_in > WIDTH/2);
    end
endmodule

// Top level glitch filter module
module async_glitch_filter #(
    parameter GLITCH_THRESHOLD = 3
)(
    input [GLITCH_THRESHOLD-1:0] samples,
    output filtered_out
);
    wire [$clog2(GLITCH_THRESHOLD+1)-1:0] ones_count;
    
    ones_counter #(
        .WIDTH(GLITCH_THRESHOLD)
    ) counter_inst (
        .data_in(samples),
        .count_out(ones_count)
    );
    
    majority_voter #(
        .WIDTH(GLITCH_THRESHOLD)
    ) voter_inst (
        .count_in(ones_count),
        .decision_out(filtered_out)
    );
endmodule