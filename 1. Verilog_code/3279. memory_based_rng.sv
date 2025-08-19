module memory_based_rng #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [3:0] addr_seed,
    output wire [WIDTH-1:0] random_val
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [3:0] addr_ptr;
    reg [WIDTH-1:0] last_val;
    
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ptr <= addr_seed;
            last_val <= 0;
            // Initialize memory with pseudo-random values
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= i * 7 + 11;
        end else begin
            // Update memory and advance pointer
            mem[addr_ptr] <= mem[addr_ptr] ^ (last_val << 1);
            last_val <= mem[addr_ptr];
            addr_ptr <= addr_ptr + last_val[1:0] + 1'b1;
        end
    end
    
    assign random_val = mem[addr_ptr];
endmodule