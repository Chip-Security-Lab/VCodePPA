//SystemVerilog
module TreeMux #(parameter DW=8, N=8) (
    input  [N-1:0][DW-1:0] din,
    input  [$clog2(N)-1:0] sel,
    output reg [DW-1:0] dout
);
generate
    if(N == 1) begin : gen_single_input
        always @* begin
            dout = din[0];
        end
    end else begin : gen_mux
        integer i;
        always @* begin : mux_flattened
            dout = {DW{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                if (sel == i[$clog2(N)-1:0])
                    dout = din[i];
            end
        end
    end
endgenerate
endmodule