//SystemVerilog
// Pipeline register module
module PipelineReg #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// Pattern matching module
module PatternMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg match
);
    wire [WIDTH-1:0] xor_result;
    
    assign xor_result = data ^ pattern;
    
    always @(posedge clk) begin
        match <= (xor_result == 0);
    end
endmodule

// Top level module
module PipelineMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output match
);
    wire [WIDTH-1:0] pipe_data;
    
    PipelineReg #(.WIDTH(WIDTH)) pipe_reg (
        .clk(clk),
        .data_in(data_in),
        .data_out(pipe_data)
    );
    
    PatternMatcher #(.WIDTH(WIDTH)) pattern_matcher (
        .clk(clk),
        .data(pipe_data),
        .pattern(pattern),
        .match(match)
    );
endmodule