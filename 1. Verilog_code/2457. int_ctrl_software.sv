module int_ctrl_software #(WIDTH=8)(
    input clk, wr_en,
    input [WIDTH-1:0] sw_int,
    output reg [WIDTH-1:0] int_out
);
always @(posedge clk) begin
    if(wr_en) int_out <= sw_int;
    else int_out <= 0;
end
endmodule