module shadow_reg #(parameter DW=16) (
    input clk, en, commit,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] working_reg, shadow_reg;
    
    always @(posedge clk) begin
        if(en) working_reg <= din;
        if(commit) shadow_reg <= working_reg;
    end
    assign dout = shadow_reg;
endmodule
