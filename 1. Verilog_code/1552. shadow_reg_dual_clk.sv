module shadow_reg_dual_clk #(parameter DW=16) (
    input main_clk, shadow_clk,
    input load, 
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] shadow_storage;
    always @(posedge main_clk) if(load) shadow_storage <= din;
    always @(posedge shadow_clk) dout <= shadow_storage;
endmodule