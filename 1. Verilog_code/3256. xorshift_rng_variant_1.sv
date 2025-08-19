//SystemVerilog
module xorshift_rng (
    input wire clk,
    input wire rst_n,
    output reg [31:0] rand_num
);

    reg [31:0] rand_num_next1;
    reg [31:0] rand_num_next2;
    reg [31:0] rand_num_next3;

    always @(*) begin
        // Stage 1: First XOR and shift
        rand_num_next1 = rand_num ^ (rand_num << 13);
        // Stage 2: Second XOR and shift
        rand_num_next2 = rand_num_next1 ^ (rand_num_next1 >> 17);
        // Stage 3: Third XOR and shift
        rand_num_next3 = rand_num_next2 ^ (rand_num_next2 << 5);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rand_num <= 32'h1;
        else
            rand_num <= rand_num_next3;
    end

endmodule