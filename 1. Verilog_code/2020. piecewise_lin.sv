module piecewise_lin #(
    parameter N = 3
)(
    input [15:0] x,
    input [15:0] knots_array [(N-1):0],
    input [15:0] slopes_array [(N-1):0],
    output [15:0] y
);
    reg [15:0] seg;
    integer i;
    
    always @(*) begin
        seg = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (x > knots_array[i]) begin
                seg = seg + (slopes_array[i] * (x - knots_array[i]));
            end
        end
    end
    
    assign y = seg;
endmodule