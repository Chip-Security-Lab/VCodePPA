module multi_phase_div #(parameter N=4) (
    input clk, rst,
    output [3:0] phase_out
);
reg [1:0] cnt;
always @(posedge clk) begin
    if(rst) cnt <= 0;
    else cnt <= cnt + 1;
end

assign phase_out = {
    cnt == 3, 
    cnt == 2, 
    cnt == 1, 
    cnt == 0
};
endmodule
