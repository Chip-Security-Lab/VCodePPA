//SystemVerilog
module int_ctrl_edge_detect #(parameter WIDTH=8)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] async_int,
    input wire valid_in,
    output wire valid_out,
    output wire [WIDTH-1:0] edge_out
);

    // 第一级流水线：同步输入数据
    reg [WIDTH-1:0] sync_reg_stage1;
    reg valid_stage1;
    
    // 第二级流水线：存储上一次的值用于边沿比较
    reg [WIDTH-1:0] sync_reg_stage2;
    reg [WIDTH-1:0] prev_reg_stage2;
    reg valid_stage2;
    
    // 插入额外的中间寄存器来切割组合逻辑路径
    reg [WIDTH-1:0] edge_calc_intermediate;
    reg valid_intermediate;
    
    // 第三级流水线：输出结果
    reg [WIDTH-1:0] edge_reg_stage3;
    reg valid_stage3;
    
    // 第一级流水线：同步和存储输入
    always @(posedge clk) begin
        if (!rst_n) begin
            sync_reg_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            sync_reg_stage1 <= async_int;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：保存前后两个周期的值
    always @(posedge clk) begin
        if (!rst_n) begin
            sync_reg_stage2 <= {WIDTH{1'b0}};
            prev_reg_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            sync_reg_stage2 <= sync_reg_stage1;
            prev_reg_stage2 <= sync_reg_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 切割组合逻辑路径的中间寄存器
    // 拆分边沿检测逻辑，将求反操作单独放在一个阶段
    always @(posedge clk) begin
        if (!rst_n) begin
            edge_calc_intermediate <= {WIDTH{1'b0}};
            valid_intermediate <= 1'b0;
        end else begin
            edge_calc_intermediate <= ~prev_reg_stage2;
            valid_intermediate <= valid_stage2;
        end
    end
    
    // 第三级流水线：完成边沿计算并输出
    always @(posedge clk) begin
        if (!rst_n) begin
            edge_reg_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            edge_reg_stage3 <= sync_reg_stage2 & edge_calc_intermediate;
            valid_stage3 <= valid_intermediate;
        end
    end
    
    // 输出赋值
    assign edge_out = edge_reg_stage3;
    assign valid_out = valid_stage3;

endmodule