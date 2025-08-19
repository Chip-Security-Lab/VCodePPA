//SystemVerilog
module config_encoding_ring #(
    parameter ENCODING = "ONEHOT" // or "BINARY"
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire flush,  // 新增流水线刷新信号
    output reg [3:0] code_out,
    output reg valid_out,
    output wire ready_out  // 新增就绪信号
);

    // 定义流水线状态
    localparam INIT_CODE = (ENCODING == "ONEHOT") ? 4'b0001 : 4'b0000;
    
    // 流水线寄存器
    reg [3:0] stage1_code, stage2_code, stage3_code;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // 计算逻辑 - 分为多个子计算以平衡各级负载
    wire [3:0] rotate_code, next_code;
    wire is_end_state;
    
    // 第一级计算 - 分析当前状态
    assign is_end_state = (ENCODING == "ONEHOT") ? code_out[3] : (code_out == 4'b1000);
    
    // 第二级计算 - 执行旋转操作
    assign rotate_code = (ENCODING == "ONEHOT") ? {code_out[0], code_out[3:1]} : code_out << 1;
    
    // 第三级计算 - 决定最终下一状态
    assign next_code = (ENCODING == "ONEHOT") ? rotate_code : 
                       (is_end_state ? 4'b0001 : rotate_code);
    
    // 就绪信号逻辑 - 允许上游控制数据流
    assign ready_out = ~(stage3_valid & ~enable);
    
    // 第一级流水线 - 计算下一状态
    always @(posedge clk) begin
        if (rst) begin
            stage1_code <= INIT_CODE;
            stage1_valid <= 1'b0;
        end
        else if (flush) begin
            stage1_valid <= 1'b0;
        end
        else if (ready_out) begin
            stage1_code <= next_code;
            stage1_valid <= enable;
        end
    end
    
    // 第二级流水线 - 中间处理
    always @(posedge clk) begin
        if (rst) begin
            stage2_code <= INIT_CODE;
            stage2_valid <= 1'b0;
        end
        else if (flush) begin
            stage2_valid <= 1'b0;
        end
        else if (ready_out) begin
            stage2_code <= stage1_code;
            stage2_valid <= stage1_valid;
        end
    end
    
    // 第三级流水线 - 最终处理
    always @(posedge clk) begin
        if (rst) begin
            stage3_code <= INIT_CODE;
            stage3_valid <= 1'b0;
        end
        else if (flush) begin
            stage3_valid <= 1'b0;
        end
        else if (ready_out) begin
            stage3_code <= stage2_code;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 输出寄存器逻辑
    always @(posedge clk) begin
        if (rst) begin
            code_out <= INIT_CODE;
            valid_out <= 1'b0;
        end
        else if (flush) begin
            valid_out <= 1'b0;
        end
        else if (ready_out) begin
            code_out <= stage3_code;
            valid_out <= stage3_valid;
        end
        else begin
            valid_out <= 1'b0;
        end
    end

endmodule