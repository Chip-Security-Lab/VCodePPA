//SystemVerilog
module usb_endpoint_ctrl #(
    parameter NUM_ENDPOINTS = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire [3:0] ep_num,
    input  wire ep_select,
    input  wire ep_stall_set,
    input  wire ep_stall_clr,
    output reg  [NUM_ENDPOINTS-1:0] ep_stall_status,
    output reg  valid_ep
);
    // 使用借位减法器实现端点有效性检查
    wire [3:0] minuend = NUM_ENDPOINTS;  // 被减数
    wire [3:0] subtrahend = ep_num;      // 减数
    
    // 借位信号
    wire [4:0] borrow;
    assign borrow[0] = 1'b0;  // 初始无借位
    
    // 差值结果
    wire [3:0] difference;
    
    // 4位借位减法器实现
    generate
        genvar i;
        for (i = 0; i < 4; i = i + 1) begin : borrow_subtractor
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            assign borrow[i+1] = (~minuend[i] & subtrahend[i]) | 
                                (~minuend[i] & borrow[i]) | 
                                (subtrahend[i] & borrow[i]);
        end
    endgenerate
    
    // 判断ep_num是否小于NUM_ENDPOINTS (差值为正且无最终借位)
    wire ep_valid = ~borrow[4];
    
    // 为stall设置/清除信号创建单独的路径以平衡逻辑延迟
    wire do_stall_set = ep_select && ep_valid && ep_stall_set;
    wire do_stall_clr = ep_select && ep_valid && ep_stall_clr && ~ep_stall_set;
    
    // 有效端点逻辑放在单独的进程中以获得更好的时序
    always @(posedge clk) begin
        if (rst)
            valid_ep <= 1'b0;
        else
            valid_ep <= ep_select && ep_valid;
    end
    
    // 端点stall状态寄存器 - 使用one-hot解码进行优化
    always @(posedge clk) begin
        if (rst) begin
            ep_stall_status <= {NUM_ENDPOINTS{1'b0}};
        end else begin
            if (do_stall_set)
                ep_stall_status[ep_num] <= 1'b1;
            else if (do_stall_clr)
                ep_stall_status[ep_num] <= 1'b0;
        end
    end
endmodule