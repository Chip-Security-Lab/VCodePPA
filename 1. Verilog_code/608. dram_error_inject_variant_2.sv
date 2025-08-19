//SystemVerilog
module dram_error_inject #(
    parameter ERROR_MASK = 8'hFF
)(
    input clk,
    input enable,
    input [63:0] data_in,
    output reg [63:0] data_out
);
    wire [63:0] error_pattern = {8{ERROR_MASK}};
    wire [63:0] error_data = data_in ^ error_pattern;
    
    always @(posedge clk) begin
        data_out <= enable ? error_data : data_in;
    end
endmodule