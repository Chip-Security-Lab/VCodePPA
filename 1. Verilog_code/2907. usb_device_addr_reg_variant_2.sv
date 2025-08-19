//SystemVerilog
module usb_device_addr_reg(
    input  wire       clk,
    input  wire       rst_b,
    input  wire       set_address,
    input  wire [6:0] new_address,
    input  wire [3:0] pid,
    input  wire [6:0] token_address,
    output reg        address_match,
    output reg  [6:0] device_address
);
    // PID类型定义
    localparam PID_SETUP = 4'b1101;
    localparam PID_IN    = 4'b1001;
    localparam PID_OUT   = 4'b0001;
    
    // 内部信号定义 - 优化为单级逻辑路径
    reg        token_addr_equals_device;
    reg        token_addr_is_zero;
    reg [1:0]  pid_type;  // 00: other, 01: setup, 10: in/out
    
    // 设备地址寄存器更新路径 - 保持不变
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            device_address <= 7'h00;
        end else if (set_address) begin
            device_address <= new_address;
        end
    end
    
    // 并行计算地址比较和PID类型判断 - 减少关键路径
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            token_addr_equals_device <= 1'b0;
            token_addr_is_zero <= 1'b0;
            pid_type <= 2'b00;
        end else begin
            token_addr_equals_device <= (token_address == device_address);
            token_addr_is_zero <= (token_address == 7'h00);
            
            // 使用case结构代替多个if条件，减少逻辑链
            case (pid)
                PID_SETUP:  pid_type <= 2'b01;
                PID_IN,
                PID_OUT:    pid_type <= 2'b10;
                default:    pid_type <= 2'b00;
            endcase
        end
    end
    
    // 直接生成匹配信号 - 合并中间逻辑级，减少流水线深度
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            address_match <= 1'b0;
        end else begin
            // 使用逻辑优化后的表达式，减少关键路径延迟
            // 原表达式：
            // (pid_is_setup && (addr_equals_device || addr_is_zero)) || (pid_is_in_out && addr_equals_device)
            // 优化为：
            // (pid_is_setup && addr_is_zero) || ((pid_is_setup || pid_is_in_out) && addr_equals_device)
            // 进一步用pid_type表示：
            case (pid_type)
                2'b01: // SETUP
                    address_match <= token_addr_equals_device || token_addr_is_zero;
                2'b10: // IN/OUT
                    address_match <= token_addr_equals_device;
                default:
                    address_match <= 1'b0;
            endcase
        end
    end
endmodule