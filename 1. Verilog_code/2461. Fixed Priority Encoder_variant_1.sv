//SystemVerilog
module fixed_priority_intr_ctrl(
  input wire clk, rst_n,
  input wire [7:0] intr_src,
  input wire intr_ready,        // 新增接收方ready信号
  output reg [2:0] intr_id,
  output reg intr_valid         // 原intr_valid信号，现作为valid信号
);
  
  // 用于确定最高优先级中断的编码变量
  reg [3:0] priority_enc;
  reg [7:0] intr_src_reg;       // 寄存中断源，确保握手过程中数据稳定
  reg pending_intr;             // 标记是否有未处理的中断
  
  // 编码优先级 - 优化为always_comb
  always @(*) begin
    casez(pending_intr ? intr_src_reg : intr_src)
      8'b1???????: priority_enc = 4'd8;  // intr_src[7]
      8'b01??????: priority_enc = 4'd7;  // intr_src[6]
      8'b001?????: priority_enc = 4'd6;  // intr_src[5]
      8'b0001????: priority_enc = 4'd5;  // intr_src[4]
      8'b00001???: priority_enc = 4'd4;  // intr_src[3]
      8'b000001??: priority_enc = 4'd3;  // intr_src[2]
      8'b0000001?: priority_enc = 4'd2;  // intr_src[1]
      8'b00000001: priority_enc = 4'd1;  // intr_src[0]
      default:     priority_enc = 4'd0;  // 无中断
    endcase
  end
  
  // 输出逻辑和握手处理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0;
      intr_valid <= 1'b0;
      intr_src_reg <= 8'b0;
      pending_intr <= 1'b0;
    end else begin
      // 检测是否有新中断，并且不在pending状态
      if ((|intr_src) && !pending_intr && !intr_valid) begin
        // 捕获新中断，置valid高
        pending_intr <= 1'b1;
        intr_src_reg <= intr_src;
        intr_valid <= 1'b1;
        
        case(priority_enc)
          4'd8: intr_id <= 3'd7;
          4'd7: intr_id <= 3'd6;
          4'd6: intr_id <= 3'd5;
          4'd5: intr_id <= 3'd4;
          4'd4: intr_id <= 3'd3;
          4'd3: intr_id <= 3'd2;
          4'd2: intr_id <= 3'd1;
          4'd1: intr_id <= 3'd0;
          default: intr_id <= intr_id;
        endcase
      end
      // 当前中断握手完成 (valid && ready)
      else if (intr_valid && intr_ready) begin
        intr_valid <= 1'b0;  // 完成一次握手，撤销valid信号
        pending_intr <= 1'b0; // 清除pending标志
        
        // 如果有新的中断源，立即处理下一个中断
        if (|intr_src) begin
          intr_src_reg <= intr_src;
          pending_intr <= 1'b1;
          intr_valid <= 1'b1;
          
          case(priority_enc)
            4'd8: intr_id <= 3'd7;
            4'd7: intr_id <= 3'd6;
            4'd6: intr_id <= 3'd5;
            4'd5: intr_id <= 3'd4;
            4'd4: intr_id <= 3'd3;
            4'd3: intr_id <= 3'd2;
            4'd2: intr_id <= 3'd1;
            4'd1: intr_id <= 3'd0;
            default: intr_id <= intr_id;
          endcase
        end
      end
    end
  end
endmodule