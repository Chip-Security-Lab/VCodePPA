module ITRC_ShiftTracker #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_in,
    output reg [WIDTH*DEPTH-1:0] history
);
    always @(posedge clk) begin
        if (!rst_n) history <= 0;
        else history <= {history[WIDTH*(DEPTH-1)-1:0], int_in};
    end
endmodule