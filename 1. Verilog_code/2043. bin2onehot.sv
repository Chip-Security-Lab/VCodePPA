module bin2onehot #(parameter IN_WIDTH = 4) (
    input wire clk, rst_n,
    input wire [IN_WIDTH-1:0] bin_in,
    output reg [(2**IN_WIDTH)-1:0] onehot_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_out <= {(2**IN_WIDTH){1'b0}};
        else
            onehot_out <= {{(2**IN_WIDTH-1){1'b0}}, 1'b1} << bin_in;
    end
endmodule