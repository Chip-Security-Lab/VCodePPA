module shadow_reg_parity #(parameter DW=8) (
    input clk, rstn, en,
    input [DW-1:0] din,
    output reg [DW:0] dout  // [DW]位为校验位
);
    wire parity = ^din;
    always @(posedge clk or negedge rstn) begin
        if(!rstn) dout <= 0;
        else if(en) dout <= {parity, din};
    end
endmodule