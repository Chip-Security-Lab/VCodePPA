//SystemVerilog
module MuxLatch #(parameter DW=4, SEL=2) (
    input clk,
    input [2**SEL-1:0][DW-1:0] din,
    input [SEL-1:0] sel,
    output reg [DW-1:0] dout
);

    reg [SEL-1:0] sel_reg;
    reg [DW-1:0] mux_out;

    always @(posedge clk) begin
        sel_reg <= sel;
        mux_out <= din[sel_reg];
        dout <= mux_out;
    end

endmodule