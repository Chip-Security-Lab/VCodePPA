module int_ctrl_trig_type #(WIDTH=4)(
    input clk,
    input [WIDTH-1:0] int_src,
    input [WIDTH-1:0] trig_type,  // 0=level 1=edge
    output [WIDTH-1:0] int_out
);
reg [WIDTH-1:0] sync_reg, prev_reg;
always @(posedge clk) begin
    prev_reg <= sync_reg;
    sync_reg <= int_src;
end
assign int_out = trig_type ? (sync_reg & ~prev_reg) : sync_reg;
endmodule