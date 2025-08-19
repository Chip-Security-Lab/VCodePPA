module rle_codec (
    input clk, 
    input [7:0] data_in,
    output reg [7:0] data_out
);
reg [7:0] count;
always @(posedge clk) begin
    if (data_in[7]) begin
        count <= data_in[6:0];
        data_out <= 8'h00;
    end else begin
        count <= count - 1;
        data_out <= data_in;
    end
end
endmodule
