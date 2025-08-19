module wave8_ramp_down #(
    parameter WIDTH = 8,
    parameter STEP  = 1
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    always @(posedge clk) begin
        if(rst) wave_out <= {WIDTH{1'b1}};
        else    wave_out <= wave_out - STEP;
    end
endmodule
