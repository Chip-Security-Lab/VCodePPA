module IIR_LPF #(parameter W=8, ALPHA=4) (
    input clk, rst_n,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) dout <= 0;
        else dout <= (ALPHA*din + (8'd255-ALPHA)*dout) >> 8;
    end
endmodule