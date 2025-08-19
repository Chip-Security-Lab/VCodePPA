//SystemVerilog
module int_ctrl_edge_detect #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] async_int,
    input wire valid_in,
    output wire [WIDTH-1:0] edge_out,
    output wire valid_out
);

    // 第一级流水线寄存器 - 同步输入数据
    reg [WIDTH-1:0] sync_stage1;
    reg valid_stage1;

    // 第二级流水线寄存器 - 保存上一个周期的值并执行边沿检测
    reg [WIDTH-1:0] edge_detect_stage2;
    reg valid_stage2;

    // 第一级流水线 - 同步异步输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            sync_stage1 <= async_int;
            valid_stage1 <= valid_in;
        end
    end

    // 第二级流水线 - 合并原第二级和第三级，直接执行边沿检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detect_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            edge_detect_stage2 <= sync_stage1 & ~sync_stage1_prev;
            valid_stage2 <= valid_stage1;
        end
    end

    // 额外的寄存器，用于保存sync_stage1的前一个值
    reg [WIDTH-1:0] sync_stage1_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1_prev <= {WIDTH{1'b0}};
        end else begin
            sync_stage1_prev <= sync_stage1;
        end
    end

    // 输出赋值
    assign edge_out = edge_detect_stage2;
    assign valid_out = valid_stage2;

endmodule