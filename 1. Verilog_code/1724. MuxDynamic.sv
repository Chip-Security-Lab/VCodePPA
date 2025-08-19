module MuxDynamic #(parameter W=8, N=4) (
    input [N*W-1:0] stream,
    input [$clog2(N)-1:0] ch_sel,
    output reg [W-1:0] active_ch
);
    integer i;
    always @(*) begin
        active_ch = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (ch_sel == i) 
                active_ch = stream[i*W +: W];
        end
    end
endmodule