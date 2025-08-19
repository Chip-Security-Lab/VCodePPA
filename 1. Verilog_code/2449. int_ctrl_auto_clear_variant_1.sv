//SystemVerilog
module int_ctrl_auto_clear #(
    parameter DW = 16
)(
    input wire clk,
    input wire rst_n,
    input wire ack,
    input wire [DW-1:0] int_src,
    input wire valid_in,
    output wire valid_out,
    output wire [DW-1:0] int_status
);

    // 流水线寄存器
    reg [DW-1:0] int_src_stage1;
    reg [DW-1:0] int_status_stage1;
    reg [DW-1:0] int_status_stage2;
    reg ack_stage1;
    reg valid_stage1, valid_stage2;
    
    // 条件求和减法算法所需的中间信号
    reg [DW-1:0] clear_mask;
    reg [DW-1:0] borrow;
    reg [DW-1:0] sub_result;
    reg [DW-1:0] status_with_new;
    
    // 第一级流水线：捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_stage1 <= {DW{1'b0}};
            int_status_stage1 <= {DW{1'b0}};
            ack_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            int_src_stage1 <= int_src;
            int_status_stage1 <= int_status;
            ack_stage1 <= ack;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：使用条件求和减法算法完成计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_status_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
            clear_mask <= {DW{1'b0}};
            borrow <= {DW{1'b0}};
            sub_result <= {DW{1'b0}};
            status_with_new <= {DW{1'b0}};
        end else begin
            if (valid_stage1) begin
                // 步骤1: 合并新的中断源
                status_with_new <= int_status_stage1 | int_src_stage1;
                
                // 步骤2: 确定需要清除的位
                clear_mask <= ack_stage1 ? int_status_stage1 : {DW{1'b0}};
                
                // 步骤3: 条件求和减法算法实现 (status_with_new - clear_mask)
                // 计算借位
                borrow[0] <= status_with_new[0] < clear_mask[0];
                
                // 按位执行减法
                sub_result[0] <= status_with_new[0] ^ clear_mask[0];
                
                // 实现8位条件求和减法
                for (integer i = 1; i < 8; i = i + 1) begin
                    borrow[i] <= (status_with_new[i] < clear_mask[i]) | 
                                ((status_with_new[i] == clear_mask[i]) & borrow[i-1]);
                    sub_result[i] <= status_with_new[i] ^ clear_mask[i] ^ borrow[i-1];
                end
                
                // 完成8位以上的条件求和减法（如果DW>8）
                for (integer i = 8; i < DW; i = i + 1) begin
                    borrow[i] <= (status_with_new[i] < clear_mask[i]) | 
                                ((status_with_new[i] == clear_mask[i]) & borrow[i-1]);
                    sub_result[i] <= status_with_new[i] ^ clear_mask[i] ^ borrow[i-1];
                end
                
                // 更新状态
                int_status_stage2 <= sub_result;
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign int_status = int_status_stage2;
    assign valid_out = valid_stage2;

endmodule