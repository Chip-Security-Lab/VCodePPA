module sram_clock_gated #(
    parameter DW = 4,
    parameter AW = 3
)(
    input main_clk,
    input enable,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
reg [DW-1:0] mem [0:(1<<AW)-1];
wire gated_clk;
assign gated_clk = main_clk & enable;

always @(posedge gated_clk) begin
    if (we) begin
        mem[addr] <= din;
        dout <= din;
    end else begin
        dout <= mem[addr];
    end
end
endmodule
