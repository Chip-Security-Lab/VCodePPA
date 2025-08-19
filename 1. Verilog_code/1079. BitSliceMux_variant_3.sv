//SystemVerilog
module BitSliceMux #(parameter N=4, DW=4) (
    input  wire [N-1:0] sel,
    input  wire [(DW*N)-1:0] din,
    output reg  [DW-1:0] dout
);
    integer idx_sel, idx_bit;
    always @* begin
        dout = {DW{1'b0}};
        idx_sel = 0;
        while (idx_sel < N) begin
            if (sel[idx_sel]) begin
                idx_bit = 0;
                while (idx_bit < DW) begin
                    dout[idx_bit] = dout[idx_bit] | din[(idx_sel*DW) + idx_bit];
                    idx_bit = idx_bit + 1;
                end
            end
            idx_sel = idx_sel + 1;
        end
    end
endmodule