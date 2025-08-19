//SystemVerilog
module MuxRecursive #(parameter W=8, N=8) (
    input [W-1:0] din [0:N-1],
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] dout
);

    // 使用补码加法实现减法器
    wire [W-1:0] sel_complement;
    wire [W-1:0] mux_result;
    
    // 计算选择信号的补码
    assign sel_complement = ~sel + 1'b1;
    
    // 使用补码加法实现多路选择
    always @(*) begin
        case (sel)
            default: dout = {W{1'b0}};
            'd0: dout = din[0] + sel_complement;
            'd1: dout = din[1] + sel_complement;
            'd2: dout = din[2] + sel_complement;
            'd3: dout = din[3] + sel_complement;
            'd4: dout = din[4] + sel_complement;
            'd5: dout = din[5] + sel_complement;
            'd6: dout = din[6] + sel_complement;
            'd7: dout = din[7] + sel_complement;
        endcase
    end

endmodule