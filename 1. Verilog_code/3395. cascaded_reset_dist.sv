module cascaded_reset_dist(
    input wire clk,
    input wire rst_in,
    output wire [3:0] rst_cascade
);
    reg [3:0] rst_reg;
    always @(posedge clk) begin
        if (rst_in)
            rst_reg <= 4'b1111;
        else
            rst_reg <= {1'b0, rst_reg[3:1]};
    end
    assign rst_cascade = rst_reg;
endmodule