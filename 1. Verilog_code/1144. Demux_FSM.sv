module Demux_FSM #(parameter DW=8) (
    input clk, rst,
    input [1:0] state,
    input [DW-1:0] data,
    output reg [3:0][DW-1:0] out
);
parameter S0=0, S1=1, S2=2, S3=3;
always @(posedge clk) begin
    if(rst) out <= 0;
    else case(state)
        S0: out[0] <= data;
        S1: out[1] <= data;
        S2: out[2] <= data;
        S3: out[3] <= data;
    endcase
end
endmodule
