//SystemVerilog
module int_ctrl_secure #(
    parameter DOMAINS = 2
)(
    input wire clk,
    input wire rst,
    input wire [DOMAINS-1:0] domain_en,
    input wire [15:0] intr_vec,
    input wire valid_in,
    output wire valid_out,
    output wire ready_in,
    output wire [3:0] secure_grant
);
    // 流水线阶段1：掩码应用及信号寄存
    reg [15:0] masked_intr_stage1;
    reg valid_stage1;
    wire ready_stage1;
    
    // 流水线阶段2：优先级编码
    reg [3:0] encoded_grant_stage2;
    reg valid_stage2;
    wire ready_stage2;
    
    // 流水线控制逻辑
    wire is_stage1_active;
    wire is_stage2_active;
    
    assign is_stage1_active = valid_stage1;
    assign is_stage2_active = valid_stage2;
    
    // 使用if-else结构替代条件运算符
    assign ready_in = !is_stage1_active || ready_stage1;
    assign ready_stage1 = !is_stage2_active || ready_stage2;
    assign ready_stage2 = 1'b1; // 最后阶段总是准备好接收新数据
    assign valid_out = valid_stage2;
    
    // 掩码生成逻辑
    wire [15:0] domain_mask;
    wire has_enabled_domain;
    
    assign has_enabled_domain = |domain_en;
    
    // 使用if-else结构实现掩码生成
    // 预计算掩码以优化时序
    assign domain_mask = {16{has_enabled_domain}};
    
    // 阶段1：掩码应用
    always @(posedge clk) begin
        if (rst) begin
            masked_intr_stage1 <= 16'b0;
            valid_stage1 <= 1'b0;
        end 
        else begin
            if (ready_stage1) begin
                if (valid_in && ready_in) begin
                    masked_intr_stage1 <= intr_vec & domain_mask;
                    valid_stage1 <= 1'b1;
                end 
                else begin
                    valid_stage1 <= 1'b0;
                end
            end
        end
    end
    
    // 优先级编码器函数 - 使用明确的if-else结构
    function [3:0] encoder;
        input [15:0] value;
        begin
            if (value[15])
                encoder = 4'd15;
            else if (value[14])
                encoder = 4'd14;
            else if (value[13])
                encoder = 4'd13;
            else if (value[12])
                encoder = 4'd12;
            else if (value[11])
                encoder = 4'd11;
            else if (value[10])
                encoder = 4'd10;
            else if (value[9])
                encoder = 4'd9;
            else if (value[8])
                encoder = 4'd8;
            else if (value[7])
                encoder = 4'd7;
            else if (value[6])
                encoder = 4'd6;
            else if (value[5])
                encoder = 4'd5;
            else if (value[4])
                encoder = 4'd4;
            else if (value[3])
                encoder = 4'd3;
            else if (value[2])
                encoder = 4'd2;
            else if (value[1])
                encoder = 4'd1;
            else if (value[0])
                encoder = 4'd0;
            else
                encoder = 4'd0;
        end
    endfunction
    
    // 阶段2：优先级编码
    always @(posedge clk) begin
        if (rst) begin
            encoded_grant_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end 
        else begin
            if (ready_stage2) begin
                if (valid_stage1 && ready_stage1) begin
                    encoded_grant_stage2 <= encoder(masked_intr_stage1);
                    valid_stage2 <= 1'b1;
                end 
                else begin
                    valid_stage2 <= 1'b0;
                end
            end
        end
    end
    
    // 输出赋值
    assign secure_grant = encoded_grant_stage2;
    
endmodule