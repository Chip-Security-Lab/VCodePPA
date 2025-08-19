module lfsr_shifter #(parameter W=8) (
    input clk, rst,
    output reg [W-1:0] prbs
);
wire feedback = prbs[7] ^ prbs[5];
always @(posedge clk or posedge rst) begin
    if(rst) prbs <= 8'hFF;
    else prbs <= {prbs[6:0], feedback};
end
endmodule