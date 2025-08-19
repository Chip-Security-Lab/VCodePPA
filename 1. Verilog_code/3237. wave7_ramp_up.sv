module wave7_ramp_up #(
    parameter WIDTH = 8,
    parameter STEP  = 2
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    always @(posedge clk) begin
        if(rst) wave_out <= 0;
        else    wave_out <= wave_out + STEP;
    end
endmodule
