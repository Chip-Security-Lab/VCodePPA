module DoubleBufferTimer #(parameter DW=8) (
    input clk, rst_n,
    input [DW-1:0] next_period,
    output reg [DW-1:0] current
);
reg [DW-1:0] buffer;
always @(posedge clk) begin
    if (!rst_n) {current, buffer} <= 0;
    else if (current == 0) begin
        current <= buffer;
        buffer <= next_period;
    end else begin
        current <= current - 1;
    end
end
endmodule