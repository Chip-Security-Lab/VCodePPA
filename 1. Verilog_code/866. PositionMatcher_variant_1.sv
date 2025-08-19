//SystemVerilog
module PositionMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output [WIDTH-1:0] match_pos
);

    // Data register submodule
    DataRegister #(.WIDTH(WIDTH)) data_reg_inst (
        .clk(clk),
        .data_in(data),
        .data_out(data_reg)
    );

    // Pattern register submodule
    DataRegister #(.WIDTH(WIDTH)) pattern_reg_inst (
        .clk(clk),
        .data_in(pattern),
        .data_out(pattern_reg)
    );

    // Comparator submodule
    Comparator #(.WIDTH(WIDTH)) comp_inst (
        .clk(clk),
        .data(data_reg),
        .pattern(pattern_reg),
        .match_pos(match_pos)
    );

endmodule

module DataRegister #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    always @(posedge clk) begin
        data_out <= data_in;
    end

endmodule

module Comparator #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg [WIDTH-1:0] match_pos
);

    integer i;

    always @(posedge clk) begin
        for (i=0; i<WIDTH; i=i+1)
            match_pos[i] <= (data[i] == pattern[i]);
    end

endmodule