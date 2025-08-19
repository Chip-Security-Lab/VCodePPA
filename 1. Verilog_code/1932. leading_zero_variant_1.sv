//SystemVerilog
module leading_zero #(parameter DW=8) (
    input  wire [DW-1:0] data,
    output reg  [$clog2(DW+1)-1:0] count
);
    integer idx;
    reg found;
    always @* begin
        count = DW[$clog2(DW+1)-1:0];
        found = 1'b0;
        idx = DW-1;
        while (idx >= 0) begin
            if (!found && data[idx]) begin
                count = DW-1-idx;
                found = 1'b1;
            end
            idx = idx - 1;
        end
    end
endmodule