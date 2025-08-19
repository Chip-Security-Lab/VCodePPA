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
    // 使用先行借位减法器算法判断ep_num是否小于NUM_ENDPOINTS
    wire [3:0] a = ep_num;
    wire [3:0] b = NUM_ENDPOINTS;
    wire [3:0] diff;
    wire [4:0] borrow;
    
    // 生成借位信号 (先行借位算法)
    assign borrow[0] = 1'b0;
    assign borrow[1] = (a[0] < b[0]) ? 1'b1 : 1'b0;
    assign borrow[2] = ((a[1] < b[1]) || ((a[1] == b[1]) && borrow[1])) ? 1'b1 : 1'b0;
    assign borrow[3] = ((a[2] < b[2]) || ((a[2] == b[2]) && borrow[2])) ? 1'b1 : 1'b0;
    assign borrow[4] = ((a[3] < b[3]) || ((a[3] == b[3]) && borrow[3])) ? 1'b1 : 1'b0;
    
    // 计算差值
    assign diff[0] = a[0] ^ b[0] ^ borrow[0];
    assign diff[1] = a[1] ^ b[1] ^ borrow[1];
    assign diff[2] = a[2] ^ b[2] ^ borrow[2];
    assign diff[3] = a[3] ^ b[3] ^ borrow[3];
    
    // 判断ep_num是否小于NUM_ENDPOINTS
    wire is_valid_ep = ~borrow[4]; // 如果最高位没有借位，说明a >= b，取反得到a < b
    
    // Decode endpoint selection early
    reg [NUM_ENDPOINTS-1:0] ep_decode;
    
    // Generate one-hot decoder for endpoint selection
    always @(*) begin
        integer i;
        ep_decode = {NUM_ENDPOINTS{1'b0}};
        if (is_valid_ep) begin
            ep_decode[ep_num] = 1'b1;
        end
    end
    
    // Split stall set and clear logic to reduce logic depth
    wire stall_update_needed = ep_select && is_valid_ep && (ep_stall_set || ep_stall_clr);
    wire stall_new_value = ep_stall_set; // If both set and clear are active, set takes precedence
    
    always @(posedge clk) begin
        if (rst) begin
            ep_stall_status <= {NUM_ENDPOINTS{1'b0}};
            valid_ep <= 1'b0;
        end else begin
            // Update valid_ep in parallel with stall status logic
            valid_ep <= ep_select && is_valid_ep;
            
            // Update stall status for the selected endpoint only
            if (stall_update_needed) begin
                case (1'b1) // Parallel case for faster synthesis
                    ep_stall_set:  ep_stall_status[ep_num] <= 1'b1;
                    ep_stall_clr:  ep_stall_status[ep_num] <= 1'b0;
                endcase
            end
        end
    end
endmodule