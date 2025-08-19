//SystemVerilog
module onehot_encoder #(
    parameter IN_WIDTH = 4
)(
    input wire [IN_WIDTH-1:0] binary_in,
    input wire valid_in,
    output reg [(1<<IN_WIDTH)-1:0] onehot_out,
    output reg error
);
    integer i, stage, shift;
    reg [(1<<IN_WIDTH)-1:0] barrel_shift [IN_WIDTH:0];

    always @(*) begin
        onehot_out = {((1<<IN_WIDTH)){1'b0}};
        error = 1'b0;

        if (valid_in) begin
            if (binary_in < (1<<IN_WIDTH)) begin
                // Initialize LSB to 1, others 0
                barrel_shift[0] = {{((1<<IN_WIDTH)-1){1'b0}}, 1'b1};
                for (stage = 0; stage < IN_WIDTH; stage = stage + 1) begin
                    if (binary_in[stage])
                        barrel_shift[stage+1] = barrel_shift[stage] << (1<<stage);
                    else
                        barrel_shift[stage+1] = barrel_shift[stage];
                end
                onehot_out = barrel_shift[IN_WIDTH];
            end else begin
                error = 1'b1;
            end
        end
    end
endmodule