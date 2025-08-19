module subtractor_8bit_sync (
    input clk, 
    input reset, 
    input [7:0] a, 
    input [7:0] b, 
    output reg [7:0] diff
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            diff <= 0;
        end else begin
            diff <= a - b;
        end
    end
endmodule
