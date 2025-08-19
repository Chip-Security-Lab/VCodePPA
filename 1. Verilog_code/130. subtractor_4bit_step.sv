module subtractor_4bit_step (
    input [3:0] a, 
    input [3:0] b, 
    output [3:0] diff
);
    integer i;
    reg [3:0] result;
    always @(*) begin
        result = 0;
        for(i = 0; i < 4; i = i + 1) begin
            result[i] = a[i] - b[i];
        end
    end
    assign diff = result;
endmodule
