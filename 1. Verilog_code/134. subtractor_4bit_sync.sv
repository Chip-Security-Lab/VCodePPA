module subtractor_4bit_sync (
    input clk, 
    input reset, 
    input [3:0] a, 
    input [3:0] b, 
    output reg [3:0] diff
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            diff <= 0;
        end else begin
            diff <= a - b;
        end
    end
endmodule
