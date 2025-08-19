//SystemVerilog
module dynamic_xor_mask #(
    parameter WIDTH = 64
)(
    input wire clk,
    input wire rst_n,    // 添加异步复位信号
    input wire valid_in, // 输入有效信号
    input wire ready_out, // 下游模块准备接收数据
    output wire ready_in, // 本模块可以接收新数据
    input wire [WIDTH-1:0] data_in,
    output reg valid_out, // 输出有效信号
    output reg [WIDTH-1:0] data_out
);
    // 常量掩码
    localparam [31:0] XOR_CONSTANT = 32'h9E3779B9;
    
    // 流水线阶段寄存器
    reg [WIDTH-1:0] mask_reg;
    
    // 第一级流水线寄存器
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器
    reg [WIDTH-1:0] mask_stage2;
    reg [WIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    // 流水线控制逻辑
    wire stage1_ready;
    wire stage2_ready;
    
    // 流水线反压控制
    assign stage2_ready = ready_out || !valid_out;
    assign stage1_ready = stage2_ready || !valid_stage2;
    assign ready_in = stage1_ready || !valid_stage1;
    
    // 第一级流水线：寄存输入，更新掩码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            mask_reg <= {WIDTH{1'b0}};
        end else if (stage1_ready) begin
            if (valid_in && ready_in) begin
                // 寄存输入数据
                data_stage1 <= data_in;
                // 更新掩码
                mask_reg <= mask_reg ^ XOR_CONSTANT;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线：计算XOR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            mask_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (stage2_ready) begin
            if (valid_stage1) begin
                // 传递掩码
                mask_stage2 <= mask_reg;
                // 传递数据
                data_stage2 <= data_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 第三级流水线：输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (ready_out) begin
            if (valid_stage2) begin
                // 计算最终异或结果
                data_out <= data_stage2 ^ mask_stage2;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule