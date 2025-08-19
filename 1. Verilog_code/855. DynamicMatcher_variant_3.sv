//SystemVerilog
module DynamicMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input load, 
    input [WIDTH-1:0] new_pattern,
    output reg match
);
    reg [WIDTH-1:0] current_pattern;
    reg [WIDTH-1:0] data_reg;
    
    always @(posedge clk) begin
        if (load) 
            current_pattern <= new_pattern;
        data_reg <= data;
        match <= (data_reg == current_pattern);
    end
endmodule