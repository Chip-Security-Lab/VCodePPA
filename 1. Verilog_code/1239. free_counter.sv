module free_counter #(parameter MAX = 255) (
    input wire clk,
    output reg [7:0] count,
    output reg tc
);
    always @(posedge clk) begin
        count <= (count == MAX) ? 8'd0 : count + 1'b1;
        tc <= (count == MAX - 1);
    end
endmodule