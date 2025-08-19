module parameterized_type_comp #(
    parameter WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] inputs [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] max_idx,
    output reg valid
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_idx <= 0;
            valid <= 0;
        end else begin
            max_idx <= 0;
            valid <= 1;
            
            for (i = 1; i < WIDTH; i = i + 1)
                if (inputs[i] > inputs[max_idx])
                    max_idx <= i[$clog2(WIDTH)-1:0];
        end
    end
endmodule