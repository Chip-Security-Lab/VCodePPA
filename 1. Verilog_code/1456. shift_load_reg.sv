module shift_load_reg(
    input clk, rst,
    input [7:0] parallel_in,
    input shift_en, load_en, serial_in,
    output reg [7:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= 8'b0;
        else if (load_en)
            q <= parallel_in;
        else if (shift_en)
            q <= {q[6:0], serial_in};
    end
endmodule