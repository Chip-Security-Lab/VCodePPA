//SystemVerilog
module sync_bidir_rotational #(
    parameter WIDTH = 64
)(
    input                   clock,
    input                   reset,
    input      [WIDTH-1:0]  in_vector,
    input      [$clog2(WIDTH)-1:0] shift_count,
    input                   direction, // 0=left, 1=right
    output     [WIDTH-1:0]  out_vector
);

    // 桶形移位器实现
    wire [WIDTH-1:0] barrel_shift_result;
    wire [WIDTH-1:0] final_result;
    
    // 桶形移位器实例化
    barrel_shifter #(
        .WIDTH(WIDTH)
    ) barrel_inst (
        .data_in(in_vector),
        .shift_amount(shift_count),
        .direction(direction),
        .data_out(barrel_shift_result)
    );
    
    // 输出寄存器实例化
    output_register #(
        .WIDTH(WIDTH)
    ) out_reg_inst (
        .clock(clock),
        .reset(reset),
        .data_in(barrel_shift_result),
        .data_out(out_vector)
    );

endmodule

// 桶形移位器子模块
module barrel_shifter #(
    parameter WIDTH = 64
)(
    input      [WIDTH-1:0]  data_in,
    input      [$clog2(WIDTH)-1:0] shift_amount,
    input                   direction,
    output     [WIDTH-1:0]  data_out
);
    // 内部连线
    wire [WIDTH-1:0] stage [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] reversed_data;
    
    // 数据反转用于右移
    assign reversed_data = {data_in[0+:WIDTH]};
    
    // 初始化第一级
    assign stage[0] = direction ? reversed_data : data_in;
    
    // 生成桶形移位器各级
    generate
        genvar i;
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin : barrel_stages
            wire [WIDTH-1:0] shifted_data;
            wire [WIDTH-1:0] unshifted_data;
            
            // 计算移位后的数据
            assign shifted_data = {stage[i][(2**i)-1:0], stage[i][WIDTH-1:2**i]};
            assign unshifted_data = stage[i];
            
            // 根据移位量选择是否移位
            assign stage[i+1] = shift_amount[i] ? shifted_data : unshifted_data;
        end
    endgenerate
    
    // 最终结果处理
    assign data_out = direction ? {stage[$clog2(WIDTH)][0+:WIDTH]} : stage[$clog2(WIDTH)];

endmodule

// 输出寄存器子模块
module output_register #(
    parameter WIDTH = 64
)(
    input                   clock,
    input                   reset,
    input      [WIDTH-1:0]  data_in,
    output reg [WIDTH-1:0]  data_out
);
    always @(posedge clock) begin
        if (reset)
            data_out <= {WIDTH{1'b0}};
        else
            data_out <= data_in;
    end
endmodule