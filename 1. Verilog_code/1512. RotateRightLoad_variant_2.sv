//SystemVerilog
// IEEE 1364-2005
module RotateRightLoad #(parameter DATA_WIDTH=8) (
    input wire clk,
    input wire rst_n,       // 添加复位信号
    input wire load_en,
    input wire data_valid_in,  // 输入数据有效信号
    input wire [DATA_WIDTH-1:0] parallel_in,
    output wire [DATA_WIDTH-1:0] data_out,
    output wire data_valid_out  // 输出数据有效信号
);

    // 流水线阶段1：加载或旋转计算
    reg [DATA_WIDTH-1:0] data_stage1;
    reg valid_stage1;
    wire [DATA_WIDTH-1:0] rotated_data = {data_stage1[0], data_stage1[DATA_WIDTH-1:1]};
    
    // 流水线阶段2：结果寄存
    reg [DATA_WIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    // 阶段1：加载或执行旋转操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= data_valid_in;
            if (data_valid_in) begin
                if (load_en) begin
                    data_stage1 <= parallel_in;
                end else begin
                    data_stage1 <= rotated_data;
                end
            end
        end
    end
    
    // 阶段2：寄存处理结果，准备输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign data_out = data_stage2;
    assign data_valid_out = valid_stage2;
    
endmodule