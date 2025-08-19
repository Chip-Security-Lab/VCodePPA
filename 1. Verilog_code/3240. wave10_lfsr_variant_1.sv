//SystemVerilog
module wave10_lfsr #(
    parameter WIDTH = 8,
    parameter TAPS  = 8'hB8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    wire feedback = ^(wave_out & TAPS);

    always @(posedge clk or posedge rst) begin
        wave_out <= rst ? {WIDTH{1'b1}} : {wave_out[WIDTH-2:0], feedback};
    end
endmodule