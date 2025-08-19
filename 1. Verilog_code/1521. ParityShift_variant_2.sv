//SystemVerilog
// IEEE 1364-2005 Verilog标准
module ParityShift #(parameter DATA_BITS=7) (
    input clk, rst, sin,
    output reg [DATA_BITS:0] sreg // [7:0] for 7+1 parity
);
    wire parity = ^sreg[DATA_BITS-1:0];

    always @(posedge clk or posedge rst) begin
        sreg <= rst ? {(DATA_BITS+1){1'b0}} : {parity, sreg[DATA_BITS-1:0], sin};
    end
endmodule