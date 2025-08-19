//SystemVerilog
module BiDirShift #(parameter BITS=8) (
    input wire clk,
    input wire rst,
    input wire dir,
    input wire s_in,
    output reg [BITS-1:0] q
);

    reg dir_reg;
    reg s_in_reg;
    reg [BITS-1:0] next_q;

    always @(posedge clk) begin
        if (rst) begin
            dir_reg <= 1'b0;
            s_in_reg <= 1'b0;
            q <= {BITS{1'b0}};
        end else begin
            dir_reg <= dir;
            s_in_reg <= s_in;
            q <= next_q;
        end
    end

    always @(*) begin
        if (dir_reg)
            next_q = {q[BITS-2:0], s_in_reg};
        else
            next_q = {s_in_reg, q[BITS-1:1]};
    end

endmodule