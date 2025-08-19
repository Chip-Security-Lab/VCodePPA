module param_jk_register #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire [WIDTH-1:0] j,
    input wire [WIDTH-1:0] k,
    output reg [WIDTH-1:0] q
);
    integer i;
    
    always @(posedge clk) begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            case ({j[i], k[i]})
                2'b00: q[i] <= q[i];
                2'b01: q[i] <= 1'b0;
                2'b10: q[i] <= 1'b1;
                2'b11: q[i] <= ~q[i];
            endcase
        end
    end
endmodule
