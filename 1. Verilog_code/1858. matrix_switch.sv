module matrix_switch #(parameter INPUTS=4, OUTPUTS=4, DATA_W=8) (
    input [DATA_W-1:0] din_0, din_1, din_2, din_3,
    input [1:0] sel_0, sel_1, sel_2, sel_3, // log2(OUTPUTS) = 2
    output reg [DATA_W-1:0] dout_0, dout_1, dout_2, dout_3
);
    always @(*) begin
        dout_0 = 0;
        dout_1 = 0;
        dout_2 = 0;
        dout_3 = 0;
        
        // 基于选择路由输入
        case(sel_0)
            2'd0: dout_0 = dout_0 | din_0;
            2'd1: dout_1 = dout_1 | din_0;
            2'd2: dout_2 = dout_2 | din_0;
            2'd3: dout_3 = dout_3 | din_0;
        endcase
        
        case(sel_1)
            2'd0: dout_0 = dout_0 | din_1;
            2'd1: dout_1 = dout_1 | din_1;
            2'd2: dout_2 = dout_2 | din_1;
            2'd3: dout_3 = dout_3 | din_1;
        endcase
        
        case(sel_2)
            2'd0: dout_0 = dout_0 | din_2;
            2'd1: dout_1 = dout_1 | din_2;
            2'd2: dout_2 = dout_2 | din_2;
            2'd3: dout_3 = dout_3 | din_2;
        endcase
        
        case(sel_3)
            2'd0: dout_0 = dout_0 | din_3;
            2'd1: dout_1 = dout_1 | din_3;
            2'd2: dout_2 = dout_2 | din_3;
            2'd3: dout_3 = dout_3 | din_3;
        endcase
    end
endmodule