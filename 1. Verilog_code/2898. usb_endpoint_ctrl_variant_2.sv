//SystemVerilog
module usb_endpoint_ctrl #(
    parameter NUM_ENDPOINTS = 4
)(
    input wire clk,
    input wire rst,
    input wire [3:0] ep_num,
    input wire ep_select,
    input wire ep_stall_set,
    input wire ep_stall_clr,
    output reg [NUM_ENDPOINTS-1:0] ep_stall_status,
    output reg valid_ep
);
    // 前移第一级比较逻辑到寄存器前
    wire ep_valid = (ep_num < NUM_ENDPOINTS);
    
    // 第一级寄存器
    reg ep_select_stage1;
    reg [3:0] ep_num_stage1;
    reg ep_stall_set_stage1;
    reg ep_stall_clr_stage1;
    reg ep_valid_stage1;
    
    // 第二级组合逻辑和寄存器
    wire valid_ep_comb = ep_select_stage1 && ep_valid_stage1;
    reg valid_ep_stage1_reg;
    reg ep_select_stage2;
    reg [3:0] ep_num_stage2;
    reg ep_stall_set_stage2;
    reg ep_stall_clr_stage2;
    reg ep_valid_stage2;
    
    // 第三级寄存器
    reg valid_ep_stage2_reg;
    
    // 第一级：输入注册
    always @(posedge clk) begin
        if (rst) begin
            ep_select_stage1 <= 1'b0;
            ep_num_stage1 <= 4'b0;
            ep_stall_set_stage1 <= 1'b0;
            ep_stall_clr_stage1 <= 1'b0;
            ep_valid_stage1 <= 1'b0;
        end else begin
            ep_select_stage1 <= ep_select;
            ep_num_stage1 <= ep_num;
            ep_stall_set_stage1 <= ep_stall_set;
            ep_stall_clr_stage1 <= ep_stall_clr;
            ep_valid_stage1 <= ep_valid;
        end
    end
    
    // 第二级：控制信号准备和验证
    always @(posedge clk) begin
        if (rst) begin
            valid_ep_stage1_reg <= 1'b0;
            ep_select_stage2 <= 1'b0;
            ep_num_stage2 <= 4'b0;
            ep_stall_set_stage2 <= 1'b0;
            ep_stall_clr_stage2 <= 1'b0;
            ep_valid_stage2 <= 1'b0;
        end else begin
            valid_ep_stage1_reg <= valid_ep_comb;
            ep_select_stage2 <= ep_select_stage1;
            ep_num_stage2 <= ep_num_stage1;
            ep_stall_set_stage2 <= ep_stall_set_stage1;
            ep_stall_clr_stage2 <= ep_stall_clr_stage1;
            ep_valid_stage2 <= ep_valid_stage1;
        end
    end
    
    // 第三级：状态更新和输出
    always @(posedge clk) begin
        if (rst) begin
            ep_stall_status <= {NUM_ENDPOINTS{1'b0}};
            valid_ep_stage2_reg <= 1'b0;
            valid_ep <= 1'b0;
        end else begin
            valid_ep_stage2_reg <= valid_ep_stage1_reg;
            valid_ep <= valid_ep_stage2_reg;
            
            if (ep_select_stage2 && ep_valid_stage2) begin
                if (ep_stall_set_stage2)
                    ep_stall_status[ep_num_stage2] <= 1'b1;
                else if (ep_stall_clr_stage2)
                    ep_stall_status[ep_num_stage2] <= 1'b0;
            end
        end
    end
endmodule