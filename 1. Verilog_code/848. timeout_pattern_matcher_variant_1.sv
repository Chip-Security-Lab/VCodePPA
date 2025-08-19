//SystemVerilog
// Top level module
module timeout_pattern_matcher #(
    parameter W = 8,
    parameter TIMEOUT = 7
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [W-1:0] data,
    input  wire [W-1:0] pattern,
    output wire match_valid,
    output wire match_result
);
    // Internal signals
    wire pattern_match;
    wire [($clog2(TIMEOUT+1)-1):0] timeout_count;
    wire timeout_reached;
    
    // Pattern comparison submodule
    pattern_comparator #(
        .WIDTH(W)
    ) u_pattern_comparator (
        .data(data),
        .pattern(pattern),
        .match(pattern_match)
    );
    
    // Timeout counter submodule
    timeout_counter #(
        .TIMEOUT(TIMEOUT)
    ) u_timeout_counter (
        .clk(clk),
        .rst_n(rst_n),
        .reset_counter(pattern_match),
        .count(timeout_count),
        .timeout_reached(timeout_reached)
    );
    
    // Match logic submodule
    match_output_logic u_match_output_logic (
        .clk(clk),
        .rst_n(rst_n),
        .pattern_match(pattern_match),
        .timeout_reached(timeout_reached),
        .match_valid(match_valid),
        .match_result(match_result)
    );
    
endmodule

// Pattern comparison submodule
module pattern_comparator #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data,
    input  wire [WIDTH-1:0] pattern,
    output wire match
);
    // Perform pattern matching using combinational logic
    assign match = (data == pattern);
    
endmodule

// Timeout counter submodule
module timeout_counter #(
    parameter TIMEOUT = 7
)(
    input  wire clk,
    input  wire rst_n,
    input  wire reset_counter,
    output reg [($clog2(TIMEOUT+1)-1):0] count,
    output wire timeout_reached
);
    // Timeout detection logic
    assign timeout_reached = (count >= TIMEOUT);
    
    // Counter implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else if (reset_counter) begin
            count <= 0;
        end else if (!timeout_reached) begin
            count <= count + 1'b1;
        end
    end
    
endmodule

// Match output logic submodule
module match_output_logic (
    input  wire clk,
    input  wire rst_n,
    input  wire pattern_match,
    input  wire timeout_reached,
    output reg  match_valid,
    output reg  match_result
);
    // Output control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_valid <= 1'b0;
            match_result <= 1'b0;
        end else if (pattern_match) begin
            match_valid <= 1'b1;
            match_result <= 1'b1;
        end else if (!timeout_reached) begin
            match_valid <= 1'b1;
            match_result <= 1'b0;
        end else begin
            match_valid <= 1'b0;
            match_result <= 1'b0;
        end
    end
    
endmodule