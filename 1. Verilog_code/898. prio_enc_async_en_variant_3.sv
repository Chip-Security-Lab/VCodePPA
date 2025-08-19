//SystemVerilog
// IEEE 1364-2005 Verilog标准
// 顶层模块 - 优先编码器
module prio_enc_async_en #(parameter BITS=4)(
  input arst, en,
  input [BITS-1:0] din,
  output [$clog2(BITS)-1:0] dout
);
  
  wire [$clog2(BITS)-1:0] encoder_out;
  wire reset_active;
  wire enable_active;
  
  // 复位和使能控制逻辑
  control_unit #(
    .BITS(BITS)
  ) u_control_unit (
    .arst(arst),
    .en(en),
    .reset_active(reset_active),
    .enable_active(enable_active)
  );
  
  // 优先编码逻辑
  priority_encoder #(
    .BITS(BITS)
  ) u_priority_encoder (
    .din(din),
    .encoder_out(encoder_out)
  );
  
  // 输出多路复用器
  output_mux #(
    .BITS(BITS)
  ) u_output_mux (
    .reset_active(reset_active),
    .enable_active(enable_active),
    .encoder_out(encoder_out),
    .dout(dout)
  );
  
endmodule

// 控制单元模块 - 处理复位和使能信号
module control_unit #(parameter BITS=4)(
  input arst,
  input en,
  output reset_active,
  output enable_active
);
  
  assign reset_active = arst;
  assign enable_active = en && !arst;
  
endmodule

// 优先编码器模块 - 执行优先编码逻辑
module priority_encoder #(parameter BITS=4)(
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] encoder_out
);
  
  integer i;
  
  always @(*) begin
    encoder_out = 0;
    for(i=BITS-1; i>=0; i=i-1)
      if(din[i]) encoder_out = i[$clog2(BITS)-1:0];
  end
  
endmodule

// 输出多路复用器模块 - 根据控制信号选择输出值
module output_mux #(parameter BITS=4)(
  input reset_active,
  input enable_active,
  input [$clog2(BITS)-1:0] encoder_out,
  output reg [$clog2(BITS)-1:0] dout
);
  
  // 控制状态编码
  localparam [1:0] RESET_STATE = 2'b10;
  localparam [1:0] ENABLE_STATE = 2'b01;
  localparam [1:0] IDLE_STATE = 2'b00;
  
  // 控制状态信号
  wire [1:0] control_state;
  assign control_state = {reset_active, enable_active};
  
  always @(*) begin
    case(control_state)
      RESET_STATE: dout = 0;
      ENABLE_STATE: dout = encoder_out;
      default: dout = 0;
    endcase
  end
  
endmodule