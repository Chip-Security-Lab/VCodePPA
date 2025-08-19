module wave5_triangle #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    reg direction;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out  <= 0;
            direction <= 1'b1;
        end else begin
            if(direction) wave_out <= wave_out + 1;
            else          wave_out <= wave_out - 1;
            if(wave_out == {WIDTH{1'b1}}) direction <= 0;
            if(wave_out == 0)            direction <= 1;
        end
    end
endmodule

