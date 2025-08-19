//SystemVerilog
module usb_address_allocator(
    input wire clk,
    input wire rst_n,
    input wire set_address_req,
    input wire [6:0] requested_address,
    input wire device_connected,
    input wire device_disconnected,
    input wire device_enumerated,
    output reg [6:0] allocated_address,
    output reg [127:0] address_in_use_map,  // Bitmap of used addresses
    output reg address_assigned,
    output reg [2:0] allocator_state
);
    localparam IDLE = 3'd0;
    localparam CHECK_ADDR = 3'd1;
    localparam ALLOCATE = 3'd2;
    localparam CONFIRM = 3'd3;
    localparam RELEASE = 3'd4;
    
    integer i;
    
    // 输入寄存器 - 将靠近输入的寄存器前移
    reg set_address_req_r;
    reg [6:0] requested_address_r;
    reg device_disconnected_r;
    reg device_enumerated_r;
    
    // 组合逻辑和内部状态
    reg [6:0] allocated_address_next;
    reg [127:0] address_in_use_map_next;
    reg address_assigned_next;
    reg [2:0] allocator_state_next;
    reg found_address;
    
    // 前向重定时 - 将输入信号寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            set_address_req_r <= 1'b0;
            requested_address_r <= 7'd0;
            device_disconnected_r <= 1'b0;
            device_enumerated_r <= 1'b0;
        end else begin
            set_address_req_r <= set_address_req;
            requested_address_r <= requested_address;
            device_disconnected_r <= device_disconnected;
            device_enumerated_r <= device_enumerated;
        end
    end
    
    // 组合逻辑部分 - 计算下一状态和输出
    always @(*) begin
        // 默认保持当前值
        allocated_address_next = allocated_address;
        address_in_use_map_next = address_in_use_map;
        address_assigned_next = address_assigned;
        allocator_state_next = allocator_state;
        found_address = 1'b0;
        
        case (allocator_state)
            IDLE: begin
                address_assigned_next = 1'b0;
                if (set_address_req_r)
                    allocator_state_next = CHECK_ADDR;
                else if (device_disconnected_r)
                    allocator_state_next = RELEASE;
            end
            
            CHECK_ADDR: begin
                if (requested_address_r > 7'd0 && 
                   !address_in_use_map[requested_address_r]) begin
                    allocated_address_next = requested_address_r;
                    allocator_state_next = ALLOCATE;
                end else begin
                    // 查找下一个可用地址
                    for (i = 1; i < 128; i = i + 1) begin
                        if (!address_in_use_map[i] && !found_address) begin
                            allocated_address_next = i[6:0];
                            found_address = 1'b1;
                        end
                    end
                    
                    if (found_address)
                        allocator_state_next = ALLOCATE;
                    else
                        allocator_state_next = IDLE; // 没有地址可用
                end
            end
            
            ALLOCATE: begin
                address_in_use_map_next[allocated_address] = 1'b1;
                address_assigned_next = 1'b1;
                allocator_state_next = CONFIRM;
            end
            
            CONFIRM: begin
                if (device_enumerated_r)
                    allocator_state_next = IDLE;
            end
            
            RELEASE: begin
                if (allocated_address > 7'd0)
                    address_in_use_map_next[allocated_address] = 1'b0;
                allocated_address_next = 7'd0;
                allocator_state_next = IDLE;
            end
            
            default: allocator_state_next = IDLE;
        endcase
    end
    
    // 时序逻辑部分 - 更新状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            allocator_state <= IDLE;
            allocated_address <= 7'd0;
            address_assigned <= 1'b0;
            address_in_use_map <= 128'd0;
        end else begin
            allocator_state <= allocator_state_next;
            allocated_address <= allocated_address_next;
            address_assigned <= address_assigned_next;
            address_in_use_map <= address_in_use_map_next;
        end
    end
endmodule