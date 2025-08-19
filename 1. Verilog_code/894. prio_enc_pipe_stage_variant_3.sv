//SystemVerilog
// IEEE 1364-2005 Verilog
module prio_enc_pipe_stage #(parameter W=32, A=5)(
  input clk, rst,
  input [W-1:0] req,
  output reg [A-1:0] addr_reg
);

  reg [W-1:0] req_pipe;
  wire [A-1:0] addr_next;
  wire [15:0] borrow_pre; // 先行借位信号
  wire [15:0] diff;       // 差值结果
  wire [15:0] a, b;       // 16位减法操作数

  // 将req_pipe分为两部分处理
  wire [15:0] req_high, req_low;
  wire high_has_req, low_has_req;
  
  assign req_high = req_pipe[31:16];
  assign req_low = req_pipe[15:0];
  
  assign high_has_req = |req_high;
  assign low_has_req = |req_low;
  
  // 根据高位是否有请求来选择处理哪部分
  assign a = high_has_req ? req_high : req_low;
  assign b = 16'h0000; // 与0相减用于找到最高位1
  
  // 先行借位减法器实现
  // 生成借位信号
  assign borrow_pre[0] = 0; // 初始无借位
  assign borrow_pre[1] = (a[0] < b[0]);
  assign borrow_pre[2] = (a[1] < b[1]) | ((a[1] == b[1]) & borrow_pre[1]);
  assign borrow_pre[3] = (a[2] < b[2]) | ((a[2] == b[2]) & borrow_pre[2]);
  assign borrow_pre[4] = (a[3] < b[3]) | ((a[3] == b[3]) & borrow_pre[3]);
  assign borrow_pre[5] = (a[4] < b[4]) | ((a[4] == b[4]) & borrow_pre[4]);
  assign borrow_pre[6] = (a[5] < b[5]) | ((a[5] == b[5]) & borrow_pre[5]);
  assign borrow_pre[7] = (a[6] < b[6]) | ((a[6] == b[6]) & borrow_pre[6]);
  assign borrow_pre[8] = (a[7] < b[7]) | ((a[7] == b[7]) & borrow_pre[7]);
  assign borrow_pre[9] = (a[8] < b[8]) | ((a[8] == b[8]) & borrow_pre[8]);
  assign borrow_pre[10] = (a[9] < b[9]) | ((a[9] == b[9]) & borrow_pre[9]);
  assign borrow_pre[11] = (a[10] < b[10]) | ((a[10] == b[10]) & borrow_pre[10]);
  assign borrow_pre[12] = (a[11] < b[11]) | ((a[11] == b[11]) & borrow_pre[11]);
  assign borrow_pre[13] = (a[12] < b[12]) | ((a[12] == b[12]) & borrow_pre[12]);
  assign borrow_pre[14] = (a[13] < b[13]) | ((a[13] == b[13]) & borrow_pre[13]);
  assign borrow_pre[15] = (a[14] < b[14]) | ((a[14] == b[14]) & borrow_pre[14]);
  
  // 计算差值
  assign diff[0] = a[0] ^ b[0] ^ borrow_pre[0];
  assign diff[1] = a[1] ^ b[1] ^ borrow_pre[1];
  assign diff[2] = a[2] ^ b[2] ^ borrow_pre[2];
  assign diff[3] = a[3] ^ b[3] ^ borrow_pre[3];
  assign diff[4] = a[4] ^ b[4] ^ borrow_pre[4];
  assign diff[5] = a[5] ^ b[5] ^ borrow_pre[5];
  assign diff[6] = a[6] ^ b[6] ^ borrow_pre[6];
  assign diff[7] = a[7] ^ b[7] ^ borrow_pre[7];
  assign diff[8] = a[8] ^ b[8] ^ borrow_pre[8];
  assign diff[9] = a[9] ^ b[9] ^ borrow_pre[9];
  assign diff[10] = a[10] ^ b[10] ^ borrow_pre[10];
  assign diff[11] = a[11] ^ b[11] ^ borrow_pre[11];
  assign diff[12] = a[12] ^ b[12] ^ borrow_pre[12];
  assign diff[13] = a[13] ^ b[13] ^ borrow_pre[13];
  assign diff[14] = a[14] ^ b[14] ^ borrow_pre[14];
  assign diff[15] = a[15] ^ b[15] ^ borrow_pre[15];
  
  // 优先级编码 - 找到最高位的1
  wire [4:0] high_addr, low_addr;
  
  assign high_addr = 
    diff[15] ? 5'd15 :
    diff[14] ? 5'd14 :
    diff[13] ? 5'd13 :
    diff[12] ? 5'd12 :
    diff[11] ? 5'd11 :
    diff[10] ? 5'd10 :
    diff[9]  ? 5'd9  :
    diff[8]  ? 5'd8  :
    diff[7]  ? 5'd7  :
    diff[6]  ? 5'd6  :
    diff[5]  ? 5'd5  :
    diff[4]  ? 5'd4  :
    diff[3]  ? 5'd3  :
    diff[2]  ? 5'd2  :
    diff[1]  ? 5'd1  :
    diff[0]  ? 5'd0  : 5'd0;
  
  // 如果使用高16位，则加上16的偏移
  assign addr_next = high_has_req ? {1'b1, high_addr[3:0]} : low_addr;
  
  // 计算低16位的地址
  assign low_addr = high_addr;
  
  always @(posedge clk) begin
    if (rst) begin
      req_pipe <= 0;
      addr_reg <= 0;
    end
    else begin
      req_pipe <= req;
      addr_reg <= addr_next;
    end
  end

endmodule