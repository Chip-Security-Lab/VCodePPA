//SystemVerilog IEEE 1364-2005
// 顶层模块
module usb_address_allocator(
    input wire clk,
    input wire rst_n,
    input wire set_address_req,
    input wire [6:0] requested_address,
    input wire device_connected,
    input wire device_disconnected,
    input wire device_enumerated,
    output wire [6:0] allocated_address,
    output wire [127:0] address_in_use_map,
    output wire address_assigned,
    output wire [5:0] allocator_state
);
    // 内部连线
    wire finder_start;
    wire [6:0] found_address;
    wire address_found;
    
    // 状态控制器子模块
    state_controller state_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .set_address_req(set_address_req),
        .device_disconnected(device_disconnected),
        .device_enumerated(device_enumerated),
        .requested_address(requested_address),
        .address_in_use_map(address_in_use_map),
        .address_found(address_found),
        .found_address(found_address),
        .finder_start(finder_start),
        .allocator_state(allocator_state),
        .allocated_address(allocated_address),
        .address_assigned(address_assigned)
    );
    
    // 地址查找器子模块
    address_finder addr_finder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(finder_start),
        .address_in_use_map(address_in_use_map),
        .found_address(found_address),
        .address_found(address_found)
    );
    
    // 地址映射管理器子模块
    address_map_manager addr_map_inst (
        .clk(clk),
        .rst_n(rst_n),
        .allocator_state(allocator_state),
        .allocated_address(allocated_address),
        .address_in_use_map(address_in_use_map)
    );
    
endmodule

// 状态控制器子模块
module state_controller(
    input wire clk,
    input wire rst_n,
    input wire set_address_req,
    input wire device_disconnected,
    input wire device_enumerated,
    input wire [6:0] requested_address,
    input wire [127:0] address_in_use_map,
    input wire address_found,
    input wire [6:0] found_address,
    output reg finder_start,
    output reg [5:0] allocator_state,
    output reg [6:0] allocated_address,
    output reg address_assigned
);
    // 状态定义 - 独冷编码 (one-cold encoding)
    localparam IDLE     = 6'b111110; // 只有第0位为0
    localparam CHECK_ADDR = 6'b111101; // 只有第1位为0
    localparam ALLOCATE = 6'b111011; // 只有第2位为0
    localparam CONFIRM  = 6'b110111; // 只有第3位为0
    localparam RELEASE  = 6'b101111; // 只有第4位为0
    localparam ERROR    = 6'b011111; // 只有第5位为0
    
    // 预计算条件表达式，减少关键路径延迟
    reg valid_requested_addr;
    reg addr_available;
    
    always @(*) begin
        valid_requested_addr = (requested_address > 7'd0);
        addr_available = !address_in_use_map[requested_address];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            allocator_state <= IDLE;
            allocated_address <= 7'd0;
            address_assigned <= 1'b0;
            finder_start <= 1'b0;
        end else begin
            // 默认值，避免锁存器
            finder_start <= 1'b0;
            
            case (allocator_state)
                IDLE: begin
                    address_assigned <= 1'b0;
                    
                    if (set_address_req) begin
                        allocator_state <= CHECK_ADDR;
                    end else if (device_disconnected) begin
                        allocator_state <= RELEASE;
                    end
                end
                
                CHECK_ADDR: begin
                    if (valid_requested_addr && addr_available) begin
                        allocated_address <= requested_address;
                        allocator_state <= ALLOCATE;
                    end else if (!finder_start && !address_found) begin
                        finder_start <= 1'b1;  // 启动地址查找
                    end else if (address_found) begin
                        allocated_address <= found_address;
                        allocator_state <= ALLOCATE;
                    end
                end
                
                ALLOCATE: begin
                    address_assigned <= 1'b1;
                    allocator_state <= CONFIRM;
                end
                
                CONFIRM: begin
                    if (device_enumerated)
                        allocator_state <= IDLE;
                end
                
                RELEASE: begin
                    if (allocated_address > 7'd0)
                        allocated_address <= 7'd0;
                    allocator_state <= IDLE;
                end
                
                default: allocator_state <= ERROR;
            endcase
        end
    end
endmodule

// 地址查找器子模块
module address_finder(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [127:0] address_in_use_map,
    output reg [6:0] found_address,
    output reg address_found
);
    // 优化扫描逻辑，分段并行处理减少关键路径
    reg [6:0] found_addr_low, found_addr_high;
    reg addr_found_low, addr_found_high;
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            found_address <= 7'd0;
            address_found <= 1'b0;
            found_addr_low <= 7'd0;
            found_addr_high <= 7'd0;
            addr_found_low <= 1'b0;
            addr_found_high <= 1'b0;
        end else if (start) begin
            // 首先复位发现标志
            addr_found_low <= 1'b0;
            addr_found_high <= 1'b0;
            
            // 并行扫描低地址段 (1-63)
            for (i = 1; i < 64; i = i + 1) begin
                if (!address_in_use_map[i] && !addr_found_low) begin
                    found_addr_low <= i[6:0];
                    addr_found_low <= 1'b1;
                end
            end
            
            // 并行扫描高地址段 (64-127)
            for (i = 64; i < 128; i = i + 1) begin
                if (!address_in_use_map[i] && !addr_found_high) begin
                    found_addr_high <= i[6:0];
                    addr_found_high <= 1'b1;
                end
            end
            
            // 合并结果，优先使用低地址段
            if (addr_found_low) begin
                found_address <= found_addr_low;
                address_found <= 1'b1;
            end else if (addr_found_high) begin
                found_address <= found_addr_high;
                address_found <= 1'b1;
            end else begin
                address_found <= 1'b0;
            end
        end
    end
endmodule

// 地址映射管理器子模块
module address_map_manager(
    input wire clk,
    input wire rst_n,
    input wire [5:0] allocator_state,
    input wire [6:0] allocated_address,
    output reg [127:0] address_in_use_map
);
    // 状态定义 - 独冷编码 (one-cold encoding)
    localparam IDLE     = 6'b111110; // 只有第0位为0
    localparam CHECK_ADDR = 6'b111101; // 只有第1位为0
    localparam ALLOCATE = 6'b111011; // 只有第2位为0
    localparam CONFIRM  = 6'b110111; // 只有第3位为0
    localparam RELEASE  = 6'b101111; // 只有第4位为0
    
    // 优化状态判断，简化条件逻辑
    reg is_allocate, is_release;
    reg valid_address;
    
    always @(*) begin
        is_allocate = (allocator_state == ALLOCATE);
        is_release = (allocator_state == RELEASE);
        valid_address = (allocated_address > 7'd0);
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_in_use_map <= 128'd0;
        end else begin
            if (is_allocate) begin
                address_in_use_map[allocated_address] <= 1'b1;
            end else if (is_release && valid_address) begin
                address_in_use_map[allocated_address] <= 1'b0;
            end
        end
    end
endmodule