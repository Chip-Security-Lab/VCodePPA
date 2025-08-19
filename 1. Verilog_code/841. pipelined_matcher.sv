module pipelined_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out
);
    reg [WIDTH-1:0] data_reg;
    reg comp_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
            comp_result <= 0;
            match_out <= 0;
        end else begin
            data_reg <= data_in;
            comp_result <= (data_reg == pattern);
            match_out <= comp_result;
        end
    end
endmodule