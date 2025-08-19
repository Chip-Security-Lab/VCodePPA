//SystemVerilog
module matrix_switch #(parameter INPUTS=4, OUTPUTS=4, DATA_W=8) (
    input [DATA_W-1:0] din_0, din_1, din_2, din_3,
    input [1:0] sel_0, sel_1, sel_2, sel_3,
    output reg [DATA_W-1:0] dout_0, dout_1, dout_2, dout_3
);
    always @(*) begin
        dout_0 = (sel_0 == 2'd0) ? din_0 : 'b0;
        dout_1 = (sel_0 == 2'd1) ? din_0 : 'b0;
        dout_2 = (sel_0 == 2'd2) ? din_0 : 'b0;
        dout_3 = (sel_0 == 2'd3) ? din_0 : 'b0;
        
        dout_0 = dout_0 | ((sel_1 == 2'd0) ? din_1 : 'b0);
        dout_1 = dout_1 | ((sel_1 == 2'd1) ? din_1 : 'b0);
        dout_2 = dout_2 | ((sel_1 == 2'd2) ? din_1 : 'b0);
        dout_3 = dout_3 | ((sel_1 == 2'd3) ? din_1 : 'b0);
        
        dout_0 = dout_0 | ((sel_2 == 2'd0) ? din_2 : 'b0);
        dout_1 = dout_1 | ((sel_2 == 2'd1) ? din_2 : 'b0);
        dout_2 = dout_2 | ((sel_2 == 2'd2) ? din_2 : 'b0);
        dout_3 = dout_3 | ((sel_2 == 2'd3) ? din_2 : 'b0);
        
        dout_0 = dout_0 | ((sel_3 == 2'd0) ? din_3 : 'b0);
        dout_1 = dout_1 | ((sel_3 == 2'd1) ? din_3 : 'b0);
        dout_2 = dout_2 | ((sel_3 == 2'd2) ? din_3 : 'b0);
        dout_3 = dout_3 | ((sel_3 == 2'd3) ? din_3 : 'b0);
    end
endmodule