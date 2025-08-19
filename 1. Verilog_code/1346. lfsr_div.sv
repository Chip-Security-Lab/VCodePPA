module lfsr_div #(parameter POLY=8'hB4) (
    input clk, rst,
    output reg clk_out
);
reg [7:0] lfsr;
wire feedback = lfsr[7];

always @(posedge clk) begin
    if(rst) begin
        lfsr <= 8'hFF;
        clk_out <= 0;
    end else begin
        lfsr <= {lfsr[6:0], 1'b0} ^ (feedback ? POLY : 0);
        clk_out <= (lfsr == 8'h00);
    end
end
endmodule
