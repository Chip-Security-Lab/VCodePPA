//SystemVerilog
module mux_with_valid #(
    parameter W = 32
)(
    input [W-1:0] in_data[0:3],
    input [1:0] select,
    input in_valid[0:3],
    output [W-1:0] out_data,
    output out_valid
);

    // 简化选择逻辑
    wire [1:0] sel_pp;
    wire [1:0] sel_pp_n;
    
    // 直接计算选择信号
    assign sel_pp[0] = select[0];
    assign sel_pp[1] = select[1] ^ (select[0] & in_valid[0]);
    
    // 计算反相选择信号
    assign sel_pp_n = ~sel_pp;
    
    // 优化数据选择逻辑
    wire [W-1:0] data_sel[0:3];
    
    // 使用位掩码进行数据选择
    assign data_sel[0] = in_data[0] & {W{sel_pp_n[1] & sel_pp_n[0]}};
    assign data_sel[1] = in_data[1] & {W{sel_pp_n[1] & sel_pp[0]}};
    assign data_sel[2] = in_data[2] & {W{sel_pp[1] & sel_pp_n[0]}};
    assign data_sel[3] = in_data[3] & {W{sel_pp[1] & sel_pp[0]}};
    
    // 优化有效信号选择
    wire valid_sel[0:3];
    
    // 直接计算有效信号
    assign valid_sel[0] = in_valid[0] & sel_pp_n[1] & sel_pp_n[0];
    assign valid_sel[1] = in_valid[1] & sel_pp_n[1] & sel_pp[0];
    assign valid_sel[2] = in_valid[2] & sel_pp[1] & sel_pp_n[0];
    assign valid_sel[3] = in_valid[3] & sel_pp[1] & sel_pp[0];
    
    // 最终输出
    assign out_data = data_sel[0] | data_sel[1] | data_sel[2] | data_sel[3];
    assign out_valid = valid_sel[0] | valid_sel[1] | valid_sel[2] | valid_sel[3];

endmodule