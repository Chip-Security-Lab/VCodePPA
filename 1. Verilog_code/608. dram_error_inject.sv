module dram_error_inject #(
    parameter ERROR_MASK = 8'hFF
)(
    input clk,
    input enable,
    input [63:0] data_in,
    output reg [63:0] data_out
);
    always @(posedge clk) begin
        data_out <= enable ? (data_in ^ {8{ERROR_MASK}}) : data_in;
    end
endmodule
