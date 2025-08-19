//SystemVerilog
module int_ctrl_mask #(
    parameter DW = 16
)(
    input wire clk,
    input wire rst_n,       // 复位信号
    input wire en,
    input wire [DW-1:0] req_in,
    input wire [DW-1:0] mask,
    input wire valid_in,    // 输入有效信号
    output wire valid_out,  // 输出有效信号
    output wire [DW-1:0] masked_req
);
    // 第一级流水线寄存器
    reg [DW-1:0] req_stage1;
    reg [DW-1:0] mask_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器
    reg [DW-1:0] masked_req_stage2;
    reg valid_stage2;
    
    // 借位信号寄存器
    reg [DW:0] borrow;
    reg [7:0] subtractor_result;
    
    // 第一级流水线 - 寄存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_stage1 <= {DW{1'b0}};
            mask_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            if (en) begin
                req_stage1 <= req_in;
                mask_stage1 <= mask;
                valid_stage1 <= valid_in;
            end
        end
    end
    
    // 第二级流水线 - 执行借位减法器操作并输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_req_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
            borrow <= {(DW+1){1'b0}};
            subtractor_result <= 8'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            // 8位借位减法器实现
            if (DW >= 8) begin
                // 计算每一位的借位
                borrow[0] = 1'b0; // 初始无借位
                
                // 8位借位减法实现
                for (integer i = 0; i < 8; i = i + 1) begin
                    subtractor_result[i] = req_stage1[i] ^ mask_stage1[i] ^ borrow[i];
                    borrow[i+1] = (~req_stage1[i] & mask_stage1[i]) | 
                                  (~req_stage1[i] & borrow[i]) | 
                                  (mask_stage1[i] & borrow[i]);
                end
                
                // 组合DW位结果
                for (integer j = 0; j < DW; j = j + 1) begin
                    if (j < 8) begin
                        masked_req_stage2[j] <= subtractor_result[j];
                    end else begin
                        masked_req_stage2[j] <= req_stage1[j] & ~mask_stage1[j];
                    end
                end
            end else begin
                // 如果DW小于8，则使用原始方法
                masked_req_stage2 <= req_stage1 & ~mask_stage1;
            end
        end
    end
    
    // 输出赋值
    assign masked_req = masked_req_stage2;
    assign valid_out = valid_stage2;
    
endmodule