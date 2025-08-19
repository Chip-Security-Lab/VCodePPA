//SystemVerilog
module EdgeMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output reg edge_match
);

    // Store previous data for edge detection
    reg [WIDTH-1:0] prev_data;
    
    // Edge detection logic
    wire is_match_now = (data_in == pattern);
    wire was_match = (prev_data == pattern);
    
    always @(posedge clk) begin
        prev_data <= data_in;
        edge_match <= was_match && !is_match_now;
    end
endmodule