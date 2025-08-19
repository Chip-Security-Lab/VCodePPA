//SystemVerilog
module CaseMux #(parameter N=4, DW=8) (
    input  wire [$clog2(N)-1:0] sel,
    input  wire [N-1:0][DW-1:0] din,
    output reg  [DW-1:0] dout
);
    integer i;
    always @* begin
        dout = {DW{1'b0}};
        if (sel == 0) begin
            dout = din[0];
        end else if (N > 1 && sel == 1) begin
            dout = din[1];
        end else if (N > 2 && sel == 2) begin
            dout = din[2];
        end else if (N > 3 && sel == 3) begin
            dout = din[3];
        end else begin
            dout = din[sel];
        end
    end
endmodule