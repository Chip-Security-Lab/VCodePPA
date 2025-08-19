module johnson_counter(
    input wire clk,
    input wire reset,
    output reg [3:0] q
);
    always @(posedge clk) begin
        if (reset)
            q <= 4'b0000;
        else
            q <= {q[2:0], ~q[3]}; // Feed inverted MSB to LSB
    end
endmodule