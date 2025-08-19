//SystemVerilog
module ResetCounter #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] reset_count
);

    wire [WIDTH-1:0] reset_count_next;

    // Combinational logic for next reset_count value
    assign reset_count_next = reset_count + {{(WIDTH-1){1'b0}}, 1'b1};

    // Sequential logic for reset_count register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_count <= reset_count_next;
    end

endmodule