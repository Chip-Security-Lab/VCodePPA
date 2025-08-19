module binary_to_thermo #(
    parameter BIN_WIDTH = 3
)(
    input [BIN_WIDTH-1:0] bin_in,
    output reg [(1<<BIN_WIDTH)-1:0] thermo_out
);
    integer k;
    
    always @(*) begin
        thermo_out = 0;
        for (k = 0; k < (1<<BIN_WIDTH); k = k + 1) begin
            if (k < bin_in)
                thermo_out[k] = 1'b1;
            else
                thermo_out[k] = 1'b0;
        end
    end
endmodule