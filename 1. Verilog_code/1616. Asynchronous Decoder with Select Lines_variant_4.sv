//SystemVerilog
module async_sel_decoder (
    input [1:0] sel,
    input enable,
    output reg [3:0] out_bus
);
    always @(*) begin
        out_bus = enable ? (4'b0001 << sel) : 4'b0000;
    end
endmodule