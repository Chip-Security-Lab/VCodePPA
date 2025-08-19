//SystemVerilog
module usb_device_addr_reg(
    input wire clk,
    input wire rst_b,
    input wire set_address,
    input wire [6:0] new_address,
    input wire [3:0] pid,
    input wire [6:0] token_address,
    output reg address_match,
    output reg [6:0] device_address
);
    // 本地参数定义
    localparam PID_SETUP = 4'b1101;
    localparam PID_IN    = 4'b1001;
    localparam PID_OUT   = 4'b0001;
    
    // 流水线阶段信号声明
    reg valid_stage1, valid_stage2;
    reg [3:0] pid_stage1, pid_stage2;
    reg [6:0] token_address_stage1, token_address_stage2;
    reg [6:0] device_address_next;
    reg address_match_stage1, address_match_stage2;
    
    // 阶段1：接收输入和地址更新逻辑
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            valid_stage1 <= 1'b0;
            pid_stage1 <= 4'b0;
            token_address_stage1 <= 7'h00;
            device_address <= 7'h00;
            device_address_next <= 7'h00;
        end else begin
            valid_stage1 <= 1'b1;
            pid_stage1 <= pid;
            token_address_stage1 <= token_address;
            
            // 设备地址更新逻辑
            if (set_address) begin
                device_address_next <= new_address;
            end else begin
                device_address_next <= device_address;
            end
            
            // 将新地址提交到输出寄存器
            device_address <= device_address_next;
        end
    end
    
    // 阶段2：地址比较逻辑
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            valid_stage2 <= 1'b0;
            pid_stage2 <= 4'b0;
            token_address_stage2 <= 7'h00;
            address_match_stage1 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            pid_stage2 <= pid_stage1;
            token_address_stage2 <= token_address_stage1;
            
            // 地址匹配逻辑 - 第一阶段计算
            case (pid_stage1)
                PID_SETUP: address_match_stage1 <= (token_address_stage1 == device_address || token_address_stage1 == 7'h00);
                PID_IN, PID_OUT: address_match_stage1 <= (token_address_stage1 == device_address);
                default: address_match_stage1 <= 1'b0;
            endcase
        end
    end
    
    // 阶段3：输出寄存器
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            address_match <= 1'b0;
        end else begin
            // 只有当流水线有效时才更新输出
            if (valid_stage2) begin
                address_match <= address_match_stage1;
            end
        end
    end
endmodule