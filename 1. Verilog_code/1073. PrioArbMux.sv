module PrioArbMux #(parameter DW=4) (
    input [3:0] req,
    input en,
    output reg [1:0] grant,
    output [DW-1:0] data
);
always @* 
    if(en) grant = req[3] ? 2'b11 : 
                  req[2] ? 2'b10 :
                  req[1] ? 2'b01 : 2'b00;
assign data = {grant, {DW-2{1'b0}}};
endmodule