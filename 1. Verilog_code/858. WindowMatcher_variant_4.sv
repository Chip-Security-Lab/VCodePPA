//SystemVerilog
module WindowMatcher #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg match
);
    reg [WIDTH-1:0] buffer [DEPTH-1:0];
    
    localparam [WIDTH-1:0] TARGET_PATTERN_0 = 8'hA1;
    localparam [WIDTH-1:0] TARGET_PATTERN_1 = 8'hB2;
    localparam [WIDTH-1:0] TARGET_PATTERN_2 = 8'hC3;
    localparam [WIDTH-1:0] TARGET_PATTERN_3 = 8'hD4;
    
    integer i;
    
    reg [3:0] pattern_match;
    reg [1:0] match_level1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= {WIDTH{1'b0}};
            end
            match <= 1'b0;
        end
        else begin
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                buffer[i] <= buffer[i-1];
            end
            buffer[0] <= data_in;
            
            pattern_match[0] <= (buffer[0] == TARGET_PATTERN_0);
            pattern_match[1] <= (buffer[1] == TARGET_PATTERN_1);
            pattern_match[2] <= (buffer[2] == TARGET_PATTERN_2);
            pattern_match[3] <= (buffer[3] == TARGET_PATTERN_3);
            
            match_level1[0] <= pattern_match[0] & pattern_match[1];
            match_level1[1] <= pattern_match[2] & pattern_match[3];
            
            match <= match_level1[0] & match_level1[1];
        end
    end
endmodule