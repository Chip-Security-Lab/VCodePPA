//SystemVerilog
module usb_device_state_machine(
    input wire clk, rst_n,
    input wire bus_reset_detected,
    input wire setup_received,
    input wire address_assigned,
    input wire configuration_set,
    input wire suspend_detected,
    input wire resume_detected,
    input wire [7:0] mult_a, // 乘法器输入A
    input wire [7:0] mult_b, // 乘法器输入B
    output reg [2:0] device_state,
    output reg remote_wakeup_enabled,
    output reg self_powered,
    output reg [7:0] interface_alternate,
    output wire [15:0] mult_result // 乘法器结果输出
);
    // USB device states per USB spec - using binary encoding for better area efficiency
    localparam [2:0] POWERED    = 3'd0;
    localparam [2:0] DEFAULT    = 3'd1;
    localparam [2:0] ADDRESS    = 3'd2;
    localparam [2:0] CONFIGURED = 3'd3;
    localparam [2:0] SUSPENDED  = 3'd4;
    
    reg [2:0] prev_state;
    reg [2:0] next_state;
    
    // 基拉斯基乘法器实现 (8位)
    // 将8位拆分为4位子乘法
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z1, z2;
    wire [3:0] a_sum, b_sum;
    wire [7:0] z1_intermediate;
    
    // 拆分输入为高4位和低4位
    assign a_high = mult_a[7:4];
    assign a_low = mult_a[3:0];
    assign b_high = mult_b[7:4];
    assign b_low = mult_b[3:0];
    
    // 计算a_high + a_low和b_high + b_low
    assign a_sum = a_high + a_low;
    assign b_sum = b_high + b_low;
    
    // 计算三个子乘积
    assign z0 = a_low * b_low;         // 低位 * 低位
    assign z2 = a_high * b_high;       // 高位 * 高位
    assign z1_intermediate = a_sum * b_sum; // (a_high + a_low) * (b_high + b_low)
    
    // 计算z1 = z1_intermediate - z2 - z0
    assign z1 = z1_intermediate - z2 - z0;
    
    // 组合最终结果: z2 << 8 + z1 << 4 + z0
    assign mult_result = {z2, 8'b0} + {4'b0, z1, 4'b0} + {8'b0, z0};
    
    // Optimized state transition logic with reduced priority chain
    always @(*) begin
        // Default: maintain current state
        next_state = device_state;
        
        // Handle suspended state special cases first (fewer conditions to check)
        if (device_state == SUSPENDED) begin
            if (bus_reset_detected)
                next_state = DEFAULT;
            else if (resume_detected)
                next_state = prev_state;
        end 
        // Handle normal state transitions with optimized conditions
        else if (bus_reset_detected) begin
            next_state = DEFAULT;
        end else if (suspend_detected) begin
            next_state = SUSPENDED;
        end else begin
            case (device_state)
                POWERED:
                    next_state = DEFAULT;
                DEFAULT: 
                    if (address_assigned) next_state = ADDRESS;
                ADDRESS: 
                    if (configuration_set) next_state = CONFIGURED;
                CONFIGURED: 
                    if (!configuration_set) next_state = ADDRESS;
                default: 
                    next_state = device_state;
            endcase
        end
    end
    
    // Sequential logic block with optimized updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            device_state <= POWERED;
            prev_state <= POWERED;
            remote_wakeup_enabled <= 1'b0;
            self_powered <= 1'b0;
            interface_alternate <= 8'h00;
        end else begin
            // State transition
            device_state <= next_state;
            
            // Store previous non-suspended state for resume operation
            if (next_state != SUSPENDED && device_state != SUSPENDED)
                prev_state <= next_state;
            
            // Control signals management - simplified to reduce logic depth
            if (bus_reset_detected) begin
                remote_wakeup_enabled <= 1'b0;
                interface_alternate <= 8'h00;
            end
        end
    end
endmodule