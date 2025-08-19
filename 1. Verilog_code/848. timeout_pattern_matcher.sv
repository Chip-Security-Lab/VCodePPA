module timeout_pattern_matcher #(parameter W = 8, TIMEOUT = 7) (
    input clk, rst_n,
    input [W-1:0] data, pattern,
    output reg match_valid, match_result
);
    reg [$clog2(TIMEOUT+1)-1:0] counter;
    wire current_match = (data == pattern);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            match_valid <= 0;
            match_result <= 0;
        end else if (current_match) begin
            counter <= 0;
            match_valid <= 1;
            match_result <= 1;
        end else if (counter < TIMEOUT) begin
            counter <= counter + 1;
            match_valid <= 1;
            match_result <= 0;
        end else begin
            match_valid <= 0;
            match_result <= 0;
        end
    end
endmodule