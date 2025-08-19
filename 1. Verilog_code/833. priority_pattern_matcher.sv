module priority_pattern_matcher #(parameter WIDTH = 8, PATTERNS = 4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] patterns [PATTERNS-1:0],
    output reg [($clog2(PATTERNS))-1:0] match_idx,
    output reg match_found
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_idx <= 0;
            match_found <= 1'b0;
        end else begin
            match_found <= 1'b0;
            for (i = PATTERNS-1; i >= 0; i = i - 1)
                if (data_in == patterns[i]) begin
                    match_idx <= i;
                    match_found <= 1'b1;
                end
        end
    end
endmodule