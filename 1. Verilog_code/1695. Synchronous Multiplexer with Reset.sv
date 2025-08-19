module sync_mux_with_reset(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    input sel, en,
    output reg [31:0] result
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 32'h0;
        else if (en)
            result <= sel ? data_b : data_a;
    end
endmodule