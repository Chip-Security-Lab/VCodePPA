module sync_down_counter #(parameter WIDTH = 8) (
    input wire clk, rst, enable,
    output reg [WIDTH-1:0] q_out
);
    always @(posedge clk) begin
        if (rst)
            q_out <= {WIDTH{1'b1}};  // Reset to all 1's
        else if (enable)
            q_out <= q_out - 1'b1;   // Count down
    end
endmodule