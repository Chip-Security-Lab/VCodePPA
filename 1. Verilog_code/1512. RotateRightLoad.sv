module RotateRightLoad #(parameter DATA_WIDTH=8) (
    input clk, load_en,
    input [DATA_WIDTH-1:0] parallel_in,
    output reg [DATA_WIDTH-1:0] data
);
always @(posedge clk) begin
    data <= load_en ? parallel_in : {data[0], data[DATA_WIDTH-1:1]};
end
endmodule