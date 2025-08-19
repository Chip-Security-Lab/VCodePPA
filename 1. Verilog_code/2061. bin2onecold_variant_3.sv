//SystemVerilog
module bin2onecold #(parameter BIN_WIDTH = 3) (
    input  wire [BIN_WIDTH-1:0] bin_in,
    output reg  [(1<<BIN_WIDTH)-1:0] onecold_out
);
    localparam OUT_WIDTH = (1 << BIN_WIDTH);
    integer i;
    always @* begin
        for (i = 0; i < OUT_WIDTH; i = i + 1) begin
            if (i == bin_in)
                onecold_out[i] = 1'b0;
            else
                onecold_out[i] = 1'b1;
        end
    end
endmodule