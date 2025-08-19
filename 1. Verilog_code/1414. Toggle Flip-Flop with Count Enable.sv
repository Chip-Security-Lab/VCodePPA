module toggle_ff_count_enable (
    input wire clk,
    input wire rst_n,
    input wire count_en,
    output reg [3:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'b0000;
        else if (count_en)
            q <= q + 1'b1;
    end
endmodule
