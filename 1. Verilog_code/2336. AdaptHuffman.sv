module AdaptHuffman (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
reg [31:0] freq [0:255];
integer i;

initial begin
    for(i=0; i<256; i=i+1)
        freq[i] = 0;
end

always @(posedge clk) begin
    if(!rst_n) begin
        for(i=0; i<256; i=i+1)
            freq[i] <= 0;
        code <= 0;
    end
    else begin
        freq[data] <= freq[data] + 1;
        code <= freq[data][15:0];
    end
end
endmodule