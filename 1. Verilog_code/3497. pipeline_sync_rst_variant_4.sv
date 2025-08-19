//SystemVerilog
module pipeline_sync_rst #(parameter WIDTH=8)(
    input wire clk,
    input wire rst,
    input wire valid_in,     // 输入数据有效信号
    output wire ready_out,   // 输出准备好接收信号
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout,
    output reg valid_out     // 输出数据有效信号
);

    // 声明流水线阶段寄存器和控制信号
    reg [WIDTH-1:0] stage1_data, stage2_data, stage3_data;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // 中间计算结果寄存器 - 切分关键路径
    reg [WIDTH-1:0] din_registered;
    reg valid_in_registered;
    
    // 流水线控制逻辑
    assign ready_out = 1'b1; // 此设计始终准备好接收新数据
    
    // 输入寄存阶段: 切分输入到第一级流水线的关键路径
    always @(posedge clk) begin
        if (rst) begin
            din_registered <= {WIDTH{1'b0}};
            valid_in_registered <= 1'b0;
        end else begin
            din_registered <= din;
            valid_in_registered <= valid_in;
        end
    end
    
    // 流水线阶段1：接收输入数据
    always @(posedge clk) begin
        if (rst) begin
            stage1_data <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end else if (valid_in_registered && ready_out) begin
            stage1_data <= din_registered;
            stage1_valid <= 1'b1;
        end else if (!valid_in_registered) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 流水线阶段2：处理中间数据
    // 数据路径分段切割，避免长组合路径
    reg [WIDTH/2-1:0] stage1_data_lower, stage1_data_upper;
    reg [WIDTH/2-1:0] stage2_data_lower, stage2_data_upper;
    
    always @(posedge clk) begin
        if (rst) begin
            stage1_data_lower <= {(WIDTH/2){1'b0}};
            stage1_data_upper <= {(WIDTH/2){1'b0}};
        end else begin
            stage1_data_lower <= stage1_data[WIDTH/2-1:0];
            stage1_data_upper <= stage1_data[WIDTH-1:WIDTH/2];
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage2_data <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
            stage2_data_lower <= {(WIDTH/2){1'b0}};
            stage2_data_upper <= {(WIDTH/2){1'b0}};
        end else begin
            stage2_data_lower <= stage1_data_lower;
            stage2_data_upper <= stage1_data_upper;
            stage2_data <= {stage1_data_upper, stage1_data_lower};
            stage2_valid <= stage1_valid;
        end
    end
    
    // 流水线阶段3：准备输出数据
    always @(posedge clk) begin
        if (rst) begin
            stage3_data <= {WIDTH{1'b0}};
            stage3_valid <= 1'b0;
        end else begin
            stage3_data <= stage2_data;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 输出逻辑分段处理
    reg [WIDTH-1:0] pre_dout;
    reg pre_valid_out;
    
    always @(posedge clk) begin
        if (rst) begin
            pre_dout <= {WIDTH{1'b0}};
            pre_valid_out <= 1'b0;
        end else begin
            pre_dout <= stage3_data;
            pre_valid_out <= stage3_valid;
        end
    end
    
    // 最终输出寄存器
    always @(posedge clk) begin
        if (rst) begin
            dout <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            dout <= pre_dout;
            valid_out <= pre_valid_out;
        end
    end

endmodule