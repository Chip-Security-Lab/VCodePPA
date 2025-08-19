//SystemVerilog
module interpolating_recovery #(
    parameter WIDTH = 12
)(
    input wire clk,
    input wire valid_in,
    input wire [WIDTH-1:0] sample_a,
    input wire [WIDTH-1:0] sample_b,
    output reg [WIDTH-1:0] interpolated,
    output reg valid_out
);
    always @(posedge clk) begin
        interpolated <= valid_in ? (sample_a + sample_b) >> 1 : interpolated;
        valid_out <= valid_in ? 1'b1 : 1'b0;
    end
endmodule