module fsm_div #(parameter EVEN=4, ODD=5) (
    input clk, mode, rst_n,
    output reg clk_out
);
reg [2:0] state;
always @(posedge clk) begin
    if(!rst_n) begin
        state <= 0;
        clk_out <= 0;
    end else begin
        state <= (mode ? (state==ODD-1) : (state==EVEN-1)) ? 0 : state + 1;
        clk_out <= (mode && state>=ODD/2) || (!mode && state>=EVEN/2);
    end
end
endmodule
