module parity_ring_counter(
    input wire clk,
    input wire rst_n,
    output reg [3:0] count,
    output wire parity // 1 if odd number of 1s
);
    assign parity = ^count; // XOR reduction for parity
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 4'b0001;
        else
            count <= {count[2:0], count[3]};
    end
endmodule
