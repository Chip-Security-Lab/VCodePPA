//SystemVerilog
module bin2onehot #(parameter IN_WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire [IN_WIDTH-1:0] bin_in,
    output reg [(1<<IN_WIDTH)-1:0] onehot_out
);
    localparam OUT_WIDTH = (1<<IN_WIDTH);

    reg bin_in_valid;

    always @(*) begin
        // Since bin_in is IN_WIDTH bits, it's always in [0, OUT_WIDTH-1]
        // Thus bin_in_valid is always 1
        bin_in_valid = 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onehot_out <= {OUT_WIDTH{1'b0}};
        end else begin
            onehot_out <= {OUT_WIDTH{1'b0}} | (bin_in_valid ? ({{(OUT_WIDTH-1){1'b0}},1'b1} << bin_in) : {OUT_WIDTH{1'b0}});
        end
    end
endmodule