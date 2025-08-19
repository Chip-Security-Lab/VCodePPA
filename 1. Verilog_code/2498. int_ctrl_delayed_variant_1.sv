//SystemVerilog
module int_ctrl_delayed #(
    parameter CYCLE = 4  // 增加流水线深度
)(
    input clk, rst,
    input [7:0] req_in,
    output reg [2:0] delayed_grant
);
    // 增加流水线级数
    reg [7:0] req_stage1;
    reg [7:0] req_stage2;
    reg [7:0] req_stage3;
    reg [7:0] req_stage4;
    
    // 拆分编码器处理为多个阶段
    reg [7:0] priority_mask_stage1;
    reg [7:0] priority_mask_stage2;
    reg [3:0] encoded_high_stage3;
    reg [3:0] encoded_low_stage3; 
    reg [2:0] encoded_value_stage4;
    
    // 第一级流水线：捕获请求并初始化优先级掩码
    always @(posedge clk) begin
        if(rst) begin
            req_stage1 <= 8'b0;
            priority_mask_stage1 <= 8'b0;
        end else begin
            req_stage1 <= req_in;
            
            // 初始化优先级处理
            priority_mask_stage1 <= req_in;
        end
    end
    
    // 第二级流水线：更新优先级掩码
    always @(posedge clk) begin
        if(rst) begin
            req_stage2 <= 8'b0;
            priority_mask_stage2 <= 8'b0;
        end else begin
            req_stage2 <= req_stage1;
            priority_mask_stage2 <= priority_mask_stage1;
        end
    end
    
    // 第三级流水线：分离高低位编码处理
    always @(posedge clk) begin
        if(rst) begin
            req_stage3 <= 8'b0;
            encoded_high_stage3 <= 4'b0;
            encoded_low_stage3 <= 4'b0;
        end else begin
            req_stage3 <= req_stage2;
            
            // 高位编码处理
            if(priority_mask_stage2[7])
                encoded_high_stage3 <= 4'd7;
            else if(priority_mask_stage2[6])
                encoded_high_stage3 <= 4'd6;
            else if(priority_mask_stage2[5])
                encoded_high_stage3 <= 4'd5;
            else if(priority_mask_stage2[4])
                encoded_high_stage3 <= 4'd4;
            else
                encoded_high_stage3 <= 4'd0;
                
            // 低位编码处理
            if(priority_mask_stage2[3])
                encoded_low_stage3 <= 4'd3;
            else if(priority_mask_stage2[2])
                encoded_low_stage3 <= 4'd2;
            else if(priority_mask_stage2[1])
                encoded_low_stage3 <= 4'd1;
            else if(priority_mask_stage2[0])
                encoded_low_stage3 <= 4'd0;
            else
                encoded_low_stage3 <= 4'd0;
        end
    end
    
    // 第四级流水线：最终编码和结果输出
    always @(posedge clk) begin
        if(rst) begin
            req_stage4 <= 8'b0;
            encoded_value_stage4 <= 3'd0;
            delayed_grant <= 3'd0;
        end else begin
            req_stage4 <= req_stage3;
            
            // 合并高低位编码结果
            if(|req_stage3[7:4])
                encoded_value_stage4 <= encoded_high_stage3[2:0];
            else
                encoded_value_stage4 <= encoded_low_stage3[2:0];
                
            // 输出最终结果
            delayed_grant <= encoded_value_stage4;
        end
    end
endmodule