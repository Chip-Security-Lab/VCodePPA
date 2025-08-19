module PriorityMatcher #(parameter WIDTH=8, DEPTH=4) (
    input [WIDTH-1:0] data,
    input [DEPTH*WIDTH-1:0] patterns,
    output reg [$clog2(DEPTH)-1:0] match_index,
    output reg valid
);
    integer i;
    
    always @* begin
        valid = 0;
        match_index = 0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (data == patterns[i*WIDTH +: WIDTH]) begin
                valid = 1;
                match_index = i[$clog2(DEPTH)-1:0];
            end
        end
    end
endmodule