//SystemVerilog
module usb_endpoint_ctrl #(
    parameter NUM_ENDPOINTS = 4
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire [3:0]              ep_num,
    input  wire                    ep_select,
    input  wire                    ep_stall_set,
    input  wire                    ep_stall_clr,
    output reg  [NUM_ENDPOINTS-1:0] ep_stall_status,
    output reg                     valid_ep
);
    // 优化的端点有效性信号生成 - 减少比较链
    wire endpoint_in_range = ~|ep_num[3:$clog2(NUM_ENDPOINTS)]; // 使用位操作进行范围检查
    wire valid_endpoint = ep_select & endpoint_in_range;
    
    // 单热码解码器用于更高效的端点选择
    reg [NUM_ENDPOINTS-1:0] ep_select_onehot;
    
    // 状态寄存器的下一状态值
    reg [NUM_ENDPOINTS-1:0] ep_stall_status_next;
    
    // 生成单热码，实现更高效的端点选择
    always @(*) begin
        ep_select_onehot = {NUM_ENDPOINTS{1'b0}};
        if (valid_endpoint) begin
            ep_select_onehot[ep_num[$clog2(NUM_ENDPOINTS)-1:0]] = 1'b1;
        end
    end
    
    // 优化的状态更新逻辑
    always @(*) begin
        // 默认保持当前状态
        ep_stall_status_next = ep_stall_status;
        
        // 使用位操作进行并行更新，避免顺序比较链
        if (valid_endpoint) begin
            if (ep_stall_set & ~ep_stall_clr) begin
                // 设置优先级高于清除
                ep_stall_status_next = ep_stall_status | ep_select_onehot;
            end else if (~ep_stall_set & ep_stall_clr) begin
                // 仅在不同时设置时清除
                ep_stall_status_next = ep_stall_status & ~ep_select_onehot;
            end
        end
    end
    
    // 状态更新和输出寄存器
    always @(posedge clk) begin
        if (rst) begin
            ep_stall_status <= {NUM_ENDPOINTS{1'b0}};
            valid_ep <= 1'b0;
        end else begin
            ep_stall_status <= ep_stall_status_next;
            valid_ep <= valid_endpoint;
        end
    end
endmodule