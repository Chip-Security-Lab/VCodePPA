module onehot_encoder #(
    parameter IN_WIDTH = 4
)(
    input wire [IN_WIDTH-1:0] binary_in,
    input wire valid_in,
    output reg [(1<<IN_WIDTH)-1:0] onehot_out,
    output reg error
);
    always @(*) begin
        onehot_out = 0;
        error = 0;
        
        if (valid_in) begin
            if (binary_in < (1<<IN_WIDTH))
                onehot_out = 1'b1 << binary_in;
            else
                error = 1'b1;
        end
    end
endmodule
