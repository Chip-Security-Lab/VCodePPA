//SystemVerilog
module bin_to_onehot #(
    parameter BIN_WIDTH = 4
)(
    input wire [BIN_WIDTH-1:0] bin_in,
    input wire enable,
    output reg [(1<<BIN_WIDTH)-1:0] onehot_out
);
    integer i, j;
    reg [(1<<BIN_WIDTH)-1:0] shift_stage [0:BIN_WIDTH];

    always @(*) begin
        // Initial value: only LSB is 1, rest are 0
        shift_stage[0] = {{((1<<BIN_WIDTH)-1){1'b0}}, 1'b1};
        i = 0;
        while (i < BIN_WIDTH) begin
            j = 0;
            while (j < (1<<BIN_WIDTH)) begin
                if (bin_in[i])
                    shift_stage[i+1][j] = (j >= (1<<i)) ? shift_stage[i][j-(1<<i)] : 1'b0;
                else
                    shift_stage[i+1][j] = shift_stage[i][j];
                j = j + 1;
            end
            i = i + 1;
        end
        if (enable)
            onehot_out = shift_stage[BIN_WIDTH];
        else
            onehot_out = {((1<<BIN_WIDTH)){1'b0}};
    end
endmodule