module TimeSliceArbiter #(parameter SLICE_WIDTH=8) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
reg [SLICE_WIDTH-1:0] counter;
always @(posedge clk) begin
    counter <= (rst || counter == 4) ? 0 : counter + 1;
    grant <= req & (1 << counter[1:0]);
end
endmodule
