//SystemVerilog
module MuxTree #(parameter W=4, N=8) (
    input [N-1:0][W-1:0] din,
    input [$clog2(N)-1:0] sel,
    output [W-1:0] dout
);
generate
    if (N == 1) begin
        assign dout = din[0];
    end
    else begin
        wire [W-1:0] upper_half [N/2-1:0];
        wire [W-1:0] lower_half [N/2-1:0];
        wire [W-1:0] stage1_out;
        
        for (genvar i = 0; i < N/2; i = i + 1) begin
            assign upper_half[i] = din[i];
            assign lower_half[i] = din[i + N/2];
        end
        
        assign stage1_out = sel[$clog2(N)-1] ? lower_half[sel[$clog2(N)-2:0]] : upper_half[sel[$clog2(N)-2:0]];
        assign dout = stage1_out;
    end
endgenerate
endmodule