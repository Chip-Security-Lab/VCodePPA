module shadow_reg_comb_out #(parameter WIDTH=8) (
    input clk, en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] shadow_reg;
    always @(posedge clk) begin
        if(en) shadow_reg <= din;
    end
    assign dout = shadow_reg;
endmodule