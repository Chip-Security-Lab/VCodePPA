//SystemVerilog
module timeout_pattern_matcher #(parameter W = 8, TIMEOUT = 7) (
    input clk, rst_n,
    input [W-1:0] data, pattern,
    output reg match_valid, match_result
);
    reg [$clog2(TIMEOUT+1)-1:0] counter;
    wire current_match = (data == pattern);
    wire timeout_reached = (counter >= TIMEOUT);
    wire [1:0] state = {current_match, timeout_reached};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            match_valid <= 0;
            match_result <= 0;
        end else begin
            case (state)
                2'b10: begin  // current_match = 1, timeout_reached = 0
                    counter <= 0;
                    match_valid <= 1;
                    match_result <= 1;
                end
                2'b00: begin  // current_match = 0, timeout_reached = 0
                    counter <= counter + 1;
                    match_valid <= 1;
                    match_result <= 0;
                end
                default: begin // timeout_reached = 1
                    match_valid <= 0;
                    match_result <= 0;
                end
            endcase
        end
    end
endmodule