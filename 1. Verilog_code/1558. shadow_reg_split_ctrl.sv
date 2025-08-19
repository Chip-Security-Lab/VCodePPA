module shadow_reg_split_ctrl #(parameter DW=12) (
    input clk, load, update,
    input [DW-1:0] datain,
    output reg [DW-1:0] dataout
);
    reg [DW-1:0] shadow;
    always @(posedge clk) begin
        if(load)    shadow <= datain;
        if(update) dataout <= shadow;
    end
endmodule
