module onehot_mux #(
    parameter DWIDTH = 8,
    parameter INPUTS = 4
)(
    input [DWIDTH-1:0] data_in [0:INPUTS-1],
    input [INPUTS-1:0] select_onehot,
    output [DWIDTH-1:0] data_out
);
    reg [DWIDTH-1:0] mux_out;
    integer i;
    
    always @(*) begin
        mux_out = {DWIDTH{1'b0}};
        for (i = 0; i < INPUTS; i = i + 1)
            if (select_onehot[i])
                mux_out = data_in[i];
    end
    
    assign data_out = mux_out;
endmodule