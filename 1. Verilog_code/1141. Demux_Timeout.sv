module Demux_Timeout #(parameter DW=8, TIMEOUT=100) (
    input clk, rst,
    input valid,
    input [DW-1:0] data_in,
    input [3:0] addr,
    output reg [15:0][DW-1:0] data_out,
    output reg timeout
);
reg [7:0] counter;
always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
        data_out <= 0;
        timeout <= 0;
    end else if (valid) begin
        data_out[addr] <= data_in;
        counter <= 0;
        timeout <= 0;
    end else begin
        counter <= (counter < TIMEOUT) ? counter + 1 : TIMEOUT;
        timeout <= (counter == TIMEOUT-1);
        if(timeout) data_out <= 0;
    end
end
endmodule
