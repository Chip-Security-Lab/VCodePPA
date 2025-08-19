module ResetCounter #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] reset_count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_count <= reset_count + 1;
    end
endmodule
