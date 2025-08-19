module rotate_right_en #(parameter W=8) (
    input clk, en, rst_n,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) dout <= 0;
    else if(en) dout <= {din[0], din[W-1:1]};
end
endmodule