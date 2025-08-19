module ArithShift #(parameter N=8) (
    input clk, rstn, arith_shift, s_in,
    output reg [N-1:0] q,
    output reg carry_out
);
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        q <= 0;
        carry_out <= 0;
    end else if (arith_shift) begin
        // Arithmetic right shift: sign-extend
        carry_out <= q[0];
        q <= {q[N-1], q[N-1:1]}; 
    end else begin
        // Logical left shift
        carry_out <= q[N-1];
        q <= {q[N-2:0], s_in};
    end
end
endmodule