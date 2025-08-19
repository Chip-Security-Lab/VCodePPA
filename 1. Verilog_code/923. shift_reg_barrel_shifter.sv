module shift_reg_barrel_shifter #(
    parameter WIDTH = 16
)(
    input                      clk,
    input                      en,
    input      [WIDTH-1:0]     data_in,
    input      [$clog2(WIDTH)-1:0] shift_amount,
    output reg [WIDTH-1:0]     data_out
);
    // 定义位移位数为常量
    localparam LOG2_WIDTH = $clog2(WIDTH);
    
    // 使用单独的寄存器替代数组
    reg [WIDTH-1:0] stage0, stage1, stage2, stage3, stage4; // 支持最大WIDTH=32的情况
    
    always @(posedge clk) begin
        if (en) begin
            // 第一阶段直接获取输入
            stage0 <= shift_amount[0] ? {data_in[WIDTH-2:0], 1'b0} : data_in;
            
            // 后续阶段以2的幂次方移位
            if(LOG2_WIDTH > 1)
                stage1 <= shift_amount[1] ? {stage0[WIDTH-3:0], 2'b0} : stage0;
            else
                stage1 <= stage0;
                
            if(LOG2_WIDTH > 2)
                stage2 <= shift_amount[2] ? {stage1[WIDTH-5:0], 4'b0} : stage1;
            else
                stage2 <= stage1;
                
            if(LOG2_WIDTH > 3)
                stage3 <= shift_amount[3] ? {stage2[WIDTH-9:0], 8'b0} : stage2;
            else
                stage3 <= stage2;
                
            if(LOG2_WIDTH > 4)
                stage4 <= shift_amount[4] ? {stage3[WIDTH-17:0], 16'b0} : stage3;
            else
                stage4 <= stage3;
            
            // 输出最终阶段
            case(LOG2_WIDTH)
                1: data_out <= stage0;
                2: data_out <= stage1;
                3: data_out <= stage2;
                4: data_out <= stage3;
                default: data_out <= stage4;
            endcase
        end
    end
endmodule