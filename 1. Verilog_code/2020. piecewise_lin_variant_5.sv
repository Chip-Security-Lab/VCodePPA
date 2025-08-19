//SystemVerilog
module piecewise_lin #(
    parameter N = 3
)(
    input  wire [15:0] x,
    input  wire [15:0] knots_array [0:N-1],
    input  wire [15:0] slopes_array [0:N-1],
    output wire [15:0] y
);
    reg [15:0] seg;
    integer idx;
    reg [15:0] sum;

    always @(*) begin : piecewise_optimized
        sum = 16'b0;
        if (x > knots_array[N-1]) begin
            for (idx = 0; idx < N; idx = idx + 1) begin
                sum = sum + (slopes_array[idx] * (x - knots_array[idx]));
            end
        end else if (x > knots_array[0]) begin
            for (idx = 0; idx < N; idx = idx + 1) begin
                if ((x > knots_array[idx]) && (x <= (idx == N-1 ? 16'hFFFF : knots_array[idx+1]))) begin
                    sum = sum + (slopes_array[idx] * (x - knots_array[idx]));
                end
            end
        end
        seg = sum;
    end

    assign y = seg;
endmodule