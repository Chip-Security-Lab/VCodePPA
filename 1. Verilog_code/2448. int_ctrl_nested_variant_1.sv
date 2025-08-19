//SystemVerilog IEEE 1364-2005
module int_ctrl_edge_detect #(parameter WIDTH=8)(
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire [WIDTH-1:0] async_int,
    input wire valid_in,  // 输入有效信号
    output wire valid_out, // 输出有效信号
    output wire [WIDTH-1:0] edge_out
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // 流水线数据寄存器
    reg [WIDTH-1:0] sync_stage1;
    reg [WIDTH-1:0] sync_stage2;
    reg [WIDTH-1:0] prev_stage3;
    reg [WIDTH-1:0] edge_stage4;
    
    // 流水线实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位所有流水线寄存器
            sync_stage1 <= {WIDTH{1'b0}};
            sync_stage2 <= {WIDTH{1'b0}};
            prev_stage3 <= {WIDTH{1'b0}};
            edge_stage4 <= {WIDTH{1'b0}};
            
            // 复位控制信号
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
        end
        else begin
            // 阶段1: 捕获异步输入并同步
            sync_stage1 <= async_int;
            valid_stage1 <= valid_in;
            
            // 阶段2: 进一步同步
            sync_stage2 <= sync_stage1;
            valid_stage2 <= valid_stage1;
            
            // 阶段3: 存储前一个值以便进行边沿检测
            prev_stage3 <= sync_stage2;
            valid_stage3 <= valid_stage2;
            
            // 阶段4: 执行边沿检测计算
            edge_stage4 <= sync_stage2 & ~prev_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 输出赋值
    assign edge_out = edge_stage4;
    assign valid_out = valid_stage4;
    
endmodule