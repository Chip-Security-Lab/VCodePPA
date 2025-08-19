module onehot2bin #(
    parameter OH_WIDTH = 8,
    parameter OUT_WIDTH = 3 // 显式指定输出宽度，避免$clog2
)(
    input wire [OH_WIDTH-1:0] onehot_in,
    output reg [OUT_WIDTH-1:0] bin_out
);
    integer j;
    
    always @(*) begin
        bin_out = {OUT_WIDTH{1'b0}};
        for (j = 0; j < OH_WIDTH; j = j + 1) begin
            if (onehot_in[j])
                bin_out = j[OUT_WIDTH-1:0];
        end
    end
endmodule