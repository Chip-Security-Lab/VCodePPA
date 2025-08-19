//SystemVerilog - IEEE 1364-2005
module CarryRotateShifter #(parameter WIDTH=8) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire carry_in,
    input wire valid_in,
    output wire valid_out,
    output wire carry_out,
    output wire [WIDTH-1:0] data_out
);
    // 优化的流水线寄存器
    reg [WIDTH-1:0] data_stage1, data_stage2;
    reg carry_stage1, carry_stage2; 
    reg valid_stage1, valid_stage2;
    
    // 第一级流水线 - 低位数据移位，使用非阻塞赋值优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {data_stage1, carry_stage1, valid_stage1} <= {{WIDTH{1'b0}}, 1'b0, 1'b0};
        end else if (en) begin
            // 优化位操作，减少输出依赖
            data_stage1 <= {data_stage2[WIDTH-2:0], carry_in};
            carry_stage1 <= data_stage2[WIDTH-1];
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 移位操作完成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {data_stage2, carry_stage2, valid_stage2} <= {{WIDTH{1'b0}}, 1'b0, 1'b0};
        end else if (en) begin
            // 批量寄存器传输
            {data_stage2, carry_stage2, valid_stage2} <= {data_stage1, carry_stage1, valid_stage1};
        end
    end
    
    // 优化的连续赋值
    assign {data_out, carry_out, valid_out} = {data_stage2, carry_stage2, valid_stage2};
    
endmodule