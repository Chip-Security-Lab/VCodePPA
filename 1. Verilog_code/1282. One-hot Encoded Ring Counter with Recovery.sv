module one_hot_ring_counter(
    input wire clk,
    input wire rst_n,
    output reg [3:0] one_hot
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            one_hot <= 4'b0001; // Start with bit 0 active
        else begin
            if (one_hot == 4'b0000)
                one_hot <= 4'b0001; // Recovery if all bits zero
            else
                one_hot <= {one_hot[2:0], one_hot[3]};
        end
    end
endmodule