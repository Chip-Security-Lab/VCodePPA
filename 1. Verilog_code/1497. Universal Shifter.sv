module universal_shifter (
    input wire clk, rst,
    input wire [1:0] mode, // 00:hold, 01:shift right, 10:shift left, 11:load
    input wire [3:0] parallel_in,
    input wire left_in, right_in,
    output reg [3:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= 4'b0000;
        else begin
            case (mode)
                2'b00: q <= q;                           // Hold
                2'b01: q <= {right_in, q[3:1]};          // Shift right
                2'b10: q <= {q[2:0], left_in};           // Shift left
                2'b11: q <= parallel_in;                 // Parallel load
            endcase
        end
    end
endmodule