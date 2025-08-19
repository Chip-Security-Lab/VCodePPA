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
    
    reg [6:0] next_addr;
    integer i;
    reg found_address;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            allocator_state <= IDLE;
            allocated_address <= 7'd0;
            address_assigned <= 1'b0;
            address_in_use_map <= 128'd0;
            next_addr <= 7'd1;  // Address 0 is default address
            found_address <= 1'b0;
        end else begin
            case (allocator_state)
                IDLE: begin
                    address_assigned <= 1'b0;
                    found_address <= 1'b0;
                    if (set_address_req)
                        allocator_state <= CHECK_ADDR;
                    else if (device_disconnected)
                        allocator_state <= RELEASE;
                end
                
                CHECK_ADDR: begin
                    if (requested_address > 7'd0 && 
                       !address_in_use_map[requested_address]) begin
                        allocated_address <= requested_address;
                        allocator_state <= ALLOCATE;
                    end else begin
                        // 查找下一个可用地址
                        found_address <= 1'b0;
                        for (i = 1; i < 128; i = i + 1) begin
                            if (!address_in_use_map[i] && !found_address) begin
                                allocated_address <= i[6:0];
                                found_address <= 1'b1;
                            end
                        end
                        
                        if (found_address)
                            allocator_state <= ALLOCATE;
                        else
                            allocator_state <= IDLE; // 没有地址可用
                    end
                end
                
                ALLOCATE: begin
                    address_in_use_map[allocated_address] <= 1'b1;
                    address_assigned <= 1'b1;
                    allocator_state <= CONFIRM;
                end
                
                CONFIRM: begin
                    if (device_enumerated)
                        allocator_state <= IDLE;
                end
                
                RELEASE: begin
                    if (allocated_address > 7'd0)
                        address_in_use_map[allocated_address] <= 1'b0;
                    allocated_address <= 7'd0;
                    allocator_state <= IDLE;
                end
                
                default: allocator_state <= IDLE;
            endcase
        end
    end
endmodule