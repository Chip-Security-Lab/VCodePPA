//SystemVerilog
module xorshift_rng (
    input wire clk,
    input wire rst_n,
    output reg [31:0] rand_num
);
    reg [31:0] x1, x2;
    always @(posedge clk or negedge rst_n) begin
        rand_num <= (!rst_n) ? 32'h1 : (x2 ^ (x2 << 5));
        x1 <= (!rst_n) ? 32'h1 : (rand_num ^ (rand_num << 13));
        x2 <= (!rst_n) ? 32'h1 : (x1 ^ (x1 >> 17));
    end
endmodule