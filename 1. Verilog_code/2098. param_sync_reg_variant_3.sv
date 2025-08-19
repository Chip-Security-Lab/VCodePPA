//SystemVerilog
module param_sync_reg #(parameter WIDTH=4) (
    input clk1,
    input clk2,
    input rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] din_reg;

    always @(posedge clk1 or posedge rst) begin
        din_reg <= rst ? {WIDTH{1'b0}} : din;
    end

    always @(posedge clk2 or posedge rst) begin
        dout <= rst ? {WIDTH{1'b0}} : din_reg;
    end
endmodule