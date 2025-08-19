//SystemVerilog
module async_peak_detector #(
    parameter W = 12
)(
    input [W-1:0] signal_in,
    input [W-1:0] current_peak,
    input reset_peak,
    output [W-1:0] peak_out
);
    wire [W-1:0] compared_value;

    peak_comparator #(.W(W)) u_peak_comparator(
        .signal_in(signal_in),
        .current_peak(current_peak),
        .compared_value(compared_value)
    );

    peak_selector #(.W(W)) u_peak_selector(
        .signal_in(signal_in),
        .compared_value(compared_value),
        .reset_peak(reset_peak),
        .peak_out(peak_out)
    );
endmodule

module peak_comparator #(
    parameter W = 12
)(
    input [W-1:0] signal_in,
    input [W-1:0] current_peak,
    output reg [W-1:0] compared_value
);
    // 先行借位减法器逻辑用于比较两个数
    wire [W-1:0] difference;
    wire [W:0] borrow;
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 计算每一位的借位和差值
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_subtractor
            assign borrow[i+1] = (~signal_in[i] & current_peak[i]) | 
                                 ((signal_in[i] == current_peak[i]) & borrow[i]);
            assign difference[i] = signal_in[i] ^ current_peak[i] ^ borrow[i];
        end
    endgenerate
    
    // 如果最终没有借位，则signal_in >= current_peak
    always @(*) begin
        compared_value = (~borrow[W]) ? signal_in : current_peak;
    end
endmodule

module peak_selector #(
    parameter W = 12
)(
    input [W-1:0] signal_in,
    input [W-1:0] compared_value,
    input reset_peak,
    output [W-1:0] peak_out
);
    assign peak_out = reset_peak ? signal_in : compared_value;
endmodule