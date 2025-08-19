//SystemVerilog
module config_encoding_ring #(
    parameter ENCODING = "ONEHOT" // or "BINARY"
)(
    input wire clk,
    input wire rst,
    input wire enable,         // 新增流水线控制信号
    input wire flush,          // 新增流水线刷新信号
    output reg [3:0] code_out,
    output reg valid_out       // 新增输出有效信号
);

    // 流水线阶段寄存器和有效信号
    reg [3:0] stage1_data, stage2_data, stage3_data;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // 计算下一个编码值的组合逻辑
    wire [3:0] next_code;
    
    // 根据编码方式生成下一个值
    generate
        if (ENCODING == "ONEHOT") begin : gen_onehot
            assign next_code = {code_out[0], code_out[3:1]};
        end
        else if (ENCODING == "BINARY") begin : gen_binary
            assign next_code = (code_out == 4'b1000) ? 4'b0001 : {code_out[2:0], 1'b0};
        end
        else begin : gen_default
            assign next_code = code_out;
        end
    endgenerate
    
    // 复位初始值 - 提取为常量避免重复计算
    wire [3:0] reset_value;
    assign reset_value = (ENCODING == "ONEHOT") ? 4'b0001 : 4'b0000;
    
    // 流水线阶段1: 计算下一个值
    always @(posedge clk) begin
        if (rst) begin
            stage1_data <= reset_value;
            stage1_valid <= 1'b0;
        end
        else if (flush) begin
            stage1_data <= reset_value;
            stage1_valid <= 1'b0;
        end
        else if (enable) begin
            stage1_data <= next_code;
            stage1_valid <= 1'b1;
        end
    end
    
    // 流水线阶段2: 负载均衡，可执行其他操作
    always @(posedge clk) begin
        if (rst) begin
            stage2_data <= reset_value;
            stage2_valid <= 1'b0;
        end
        else if (flush) begin
            stage2_data <= reset_value;
            stage2_valid <= 1'b0;
        end
        else if (enable) begin
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end
    
    // 流水线阶段3: 再次负载均衡
    always @(posedge clk) begin
        if (rst) begin
            stage3_data <= reset_value;
            stage3_valid <= 1'b0;
        end
        else if (flush) begin
            stage3_data <= reset_value;
            stage3_valid <= 1'b0;
        end
        else if (enable) begin
            stage3_data <= stage2_data;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        if (rst) begin
            code_out <= reset_value;
            valid_out <= 1'b0;
        end
        else if (flush) begin
            code_out <= reset_value;
            valid_out <= 1'b0;
        end
        else if (enable) begin
            code_out <= stage3_data;
            valid_out <= stage3_valid;
        end
    end

endmodule