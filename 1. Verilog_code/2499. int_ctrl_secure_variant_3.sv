//SystemVerilog
module int_ctrl_secure #(
    parameter DOMAINS = 2
)(
    input wire clk, rst,
    input wire [DOMAINS-1:0] domain_en,
    input wire [15:0] intr_vec,
    output reg [3:0] secure_grant
);
    // IEEE 1364-2005 Verilog standard compliant code
    
    // 流水线阶段1: 域掩码生成
    reg [DOMAINS-1:0] domain_en_stage1;
    reg [15:0] intr_vec_stage1;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            domain_en_stage1 <= {DOMAINS{1'b0}};
            intr_vec_stage1 <= 16'b0;
        end
        else begin
            domain_en_stage1 <= domain_en;
            intr_vec_stage1 <= intr_vec;
        end
    end
    
    // 流水线阶段2: 掩码计算
    reg [15:0] domain_mask_stage2;
    reg [15:0] intr_vec_stage2;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            domain_mask_stage2 <= 16'b0;
            intr_vec_stage2 <= 16'b0;
        end
        else begin
            domain_mask_stage2 <= {16{|domain_en_stage1}};
            intr_vec_stage2 <= intr_vec_stage1;
        end
    end
    
    // 流水线阶段3: 应用掩码
    reg [15:0] masked_intr_stage3;
    reg has_intr_stage3;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            masked_intr_stage3 <= 16'b0;
            has_intr_stage3 <= 1'b0;
        end
        else begin
            masked_intr_stage3 <= intr_vec_stage2 & domain_mask_stage2;
            has_intr_stage3 <= |intr_vec_stage2;
        end
    end
    
    // 流水线阶段4: 优先级编码第一部分（高8位处理）
    reg [3:0] high_priority_stage4;
    reg [15:0] masked_intr_stage4;
    reg has_intr_stage4;
    reg has_high_priority_stage4;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            high_priority_stage4 <= 4'd0;
            masked_intr_stage4 <= 16'b0;
            has_intr_stage4 <= 1'b0;
            has_high_priority_stage4 <= 1'b0;
        end
        else begin
            masked_intr_stage4 <= masked_intr_stage3;
            has_intr_stage4 <= has_intr_stage3;
            
            casez(masked_intr_stage3[15:8])
                8'b1???????: begin high_priority_stage4 <= 4'd15; has_high_priority_stage4 <= 1'b1; end
                8'b01??????: begin high_priority_stage4 <= 4'd14; has_high_priority_stage4 <= 1'b1; end
                8'b001?????: begin high_priority_stage4 <= 4'd13; has_high_priority_stage4 <= 1'b1; end
                8'b0001????: begin high_priority_stage4 <= 4'd12; has_high_priority_stage4 <= 1'b1; end
                8'b00001???: begin high_priority_stage4 <= 4'd11; has_high_priority_stage4 <= 1'b1; end
                8'b000001??: begin high_priority_stage4 <= 4'd10; has_high_priority_stage4 <= 1'b1; end
                8'b0000001?: begin high_priority_stage4 <= 4'd9;  has_high_priority_stage4 <= 1'b1; end
                8'b00000001: begin high_priority_stage4 <= 4'd8;  has_high_priority_stage4 <= 1'b1; end
                default:     begin high_priority_stage4 <= 4'd0;  has_high_priority_stage4 <= 1'b0; end
            endcase
        end
    end
    
    // 流水线阶段5: 优先级编码第二部分（低8位处理）
    reg [3:0] low_priority_stage5;
    reg has_high_priority_stage5;
    reg [3:0] high_priority_stage5;
    reg has_intr_stage5;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            low_priority_stage5 <= 4'd0;
            has_high_priority_stage5 <= 1'b0;
            high_priority_stage5 <= 4'd0;
            has_intr_stage5 <= 1'b0;
        end
        else begin
            has_high_priority_stage5 <= has_high_priority_stage4;
            high_priority_stage5 <= high_priority_stage4;
            has_intr_stage5 <= has_intr_stage4;
            
            casez(masked_intr_stage4[7:0])
                8'b1???????: low_priority_stage5 <= 4'd7;
                8'b01??????: low_priority_stage5 <= 4'd6;
                8'b001?????: low_priority_stage5 <= 4'd5;
                8'b0001????: low_priority_stage5 <= 4'd4;
                8'b00001???: low_priority_stage5 <= 4'd3;
                8'b000001??: low_priority_stage5 <= 4'd2;
                8'b0000001?: low_priority_stage5 <= 4'd1;
                8'b00000001: low_priority_stage5 <= 4'd0;
                default:     low_priority_stage5 <= 4'd0;
            endcase
        end
    end
    
    // 流水线阶段6: 优先级合并
    reg [3:0] encoded_priority_stage6;
    reg has_intr_stage6;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded_priority_stage6 <= 4'd0;
            has_intr_stage6 <= 1'b0;
        end
        else begin
            has_intr_stage6 <= has_intr_stage5;
            if (has_high_priority_stage5) begin
                encoded_priority_stage6 <= high_priority_stage5;
            end
            else begin
                encoded_priority_stage6 <= low_priority_stage5;
            end
        end
    end
    
    // 流水线阶段7: 缓冲器1
    reg [3:0] encoded_buf1_stage7;
    reg has_intr_stage7;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded_buf1_stage7 <= 4'd0;
            has_intr_stage7 <= 1'b0;
        end
        else begin
            encoded_buf1_stage7 <= encoded_priority_stage6;
            has_intr_stage7 <= has_intr_stage6;
        end
    end
    
    // 流水线阶段8: 输出选择
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            secure_grant <= 4'd0;
        end
        else begin
            if (has_intr_stage7) begin
                secure_grant <= encoded_buf1_stage7;
            end
            else begin
                secure_grant <= 4'd0;
            end
        end
    end
    
endmodule