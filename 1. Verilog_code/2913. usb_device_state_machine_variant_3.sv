//SystemVerilog
module usb_device_state_machine(
    input wire clk, rst_n,
    input wire bus_reset_detected,
    input wire setup_received,
    input wire address_assigned,
    input wire configuration_set,
    input wire suspend_detected,
    input wire resume_detected,
    output reg [2:0] device_state,
    output reg remote_wakeup_enabled,
    output reg self_powered,
    output reg [7:0] interface_alternate
);
    // USB device states per USB spec
    localparam POWERED = 3'd0;
    localparam DEFAULT = 3'd1;
    localparam ADDRESS = 3'd2;
    localparam CONFIGURED = 3'd3;
    localparam SUSPENDED = 3'd4;
    
    reg [2:0] prev_state;
    reg [2:0] next_state;
    reg is_suspended;
    reg should_reset;
    reg should_suspend;
    reg should_resume;
    reg should_change_normal;
    
    // 并行计算各条件判断，减少关键路径长度
    always @(*) begin
        should_reset = bus_reset_detected;
        should_suspend = suspend_detected && (device_state != SUSPENDED);
        should_resume = resume_detected && (device_state == SUSPENDED);
        should_change_normal = ~should_reset && ~should_suspend && ~should_resume;
        
        // 预先计算是否处于挂起状态，减少逻辑深度
        is_suspended = (device_state == SUSPENDED);
        
        // 默认保持当前状态
        next_state = device_state;
        
        // 优化状态转换逻辑，平衡判断路径
        if (should_reset) begin
            next_state = DEFAULT;
        end else if (should_suspend) begin
            next_state = SUSPENDED;
        end else if (should_resume) begin
            next_state = prev_state;
        end else if (should_change_normal) begin
            case (device_state)
                DEFAULT: next_state = address_assigned ? ADDRESS : DEFAULT;
                ADDRESS: next_state = configuration_set ? CONFIGURED : ADDRESS;
                CONFIGURED: next_state = configuration_set ? CONFIGURED : ADDRESS;
                default: next_state = device_state;
            endcase
        end
    end
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            device_state <= POWERED;
            prev_state <= POWERED;
            remote_wakeup_enabled <= 1'b0;
            self_powered <= 1'b0;
            interface_alternate <= 8'h00;
        end else begin
            prev_state <= device_state;
            device_state <= next_state;
            
            if (should_reset) begin
                remote_wakeup_enabled <= 1'b0;
                interface_alternate <= 8'h00;
            end
        end
    end
endmodule