//SystemVerilog
module priority_pattern_matcher #(parameter WIDTH = 8, PATTERNS = 4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] patterns [PATTERNS-1:0],
    output reg [($clog2(PATTERNS))-1:0] match_idx,
    output reg match_found
);

    reg [WIDTH-1:0] inverted_data;
    reg [WIDTH-1:0] inverted_patterns [PATTERNS-1:0];
    reg [WIDTH-1:0] diff [PATTERNS-1:0];
    reg [PATTERNS-1:0] match_flags;
    integer i;

    always @(*) begin
        inverted_data = ~data_in;
        for (i = 0; i < PATTERNS; i = i + 1) begin
            inverted_patterns[i] = ~patterns[i];
            diff[i] = inverted_data + inverted_patterns[i] + 1;
            match_flags[i] = (diff[i] == {WIDTH{1'b0}});
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_idx <= 0;
            match_found <= 1'b0;
        end else begin
            match_found <= 1'b0;
            for (i = PATTERNS-1; i >= 0; i = i - 1)
                if (match_flags[i]) begin
                    match_idx <= i;
                    match_found <= 1'b1;
                end
        end
    end
endmodule