module xorshift_rng (
    input wire clk,
    input wire rst_n,
    output reg [31:0] rand_num
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rand_num <= 32'h1;
        else begin
            rand_num <= rand_num ^ (rand_num << 13);
            rand_num <= rand_num ^ (rand_num >> 17);
            rand_num <= rand_num ^ (rand_num << 5);
        end
    end
endmodule