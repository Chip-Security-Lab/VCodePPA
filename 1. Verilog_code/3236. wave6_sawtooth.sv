module wave6_sawtooth #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    always @(posedge clk or posedge rst) begin
        if(rst) wave_out <= 0;
        else    wave_out <= wave_out + 1;
    end
endmodule
