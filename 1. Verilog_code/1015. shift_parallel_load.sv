module shift_parallel_load #(parameter DEPTH=4) (
    input clk, load,
    input [7:0] pdata,
    output reg [7:0] sout
);
reg [7:0] shift_reg;
always @(posedge clk) begin
    if(load) shift_reg <= pdata;
    else shift_reg <= {shift_reg[6:0], 1'b0};
    sout <= shift_reg;
end
endmodule