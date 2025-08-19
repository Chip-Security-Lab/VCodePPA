module shift_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n, data_in,
    input [WIDTH-1:0] pattern,
    output reg match_out
);
    reg [WIDTH-1:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {WIDTH{1'b0}};
        else
            shift_reg <= {shift_reg[WIDTH-2:0], data_in};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
        else
            match_out <= (shift_reg == pattern);
    end
endmodule