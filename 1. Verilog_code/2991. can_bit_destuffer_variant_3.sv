//SystemVerilog
// 顶层模块
module can_bit_destuffer(
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  input  wire data_valid,
  output wire data_ready,
  input  wire destuffing_active,
  output wire data_out,
  output wire data_out_valid,
  input  wire data_out_ready,
  output wire stuff_error
);

  // 内部连线
  wire [2:0] same_bit_count;
  wire       last_bit;
  wire       processing;
  wire       update_count;
  wire       is_stuff_bit;
  wire       is_error;
  wire       count_reset;

  // 状态控制单元
  can_destuff_ctrl_unit ctrl_unit (
    .clk               (clk),
    .rst_n             (rst_n),
    .data_valid        (data_valid),
    .data_out_ready    (data_out_ready),
    .destuffing_active (destuffing_active),
    .is_stuff_bit      (is_stuff_bit),
    .is_error          (is_error),
    .data_ready        (data_ready),
    .data_out_valid    (data_out_valid),
    .processing        (processing)
  );

  // 位计数单元
  can_destuff_counter counter_unit (
    .clk           (clk),
    .rst_n         (rst_n),
    .data_in       (data_in),
    .last_bit      (last_bit),
    .update_count  (update_count),
    .count_reset   (count_reset),
    .same_bit_count(same_bit_count)
  );

  // 位检测和处理单元
  can_destuff_detector detector_unit (
    .clk               (clk),
    .rst_n             (rst_n),
    .data_in           (data_in),
    .data_valid        (data_valid),
    .data_ready        (data_ready),
    .destuffing_active (destuffing_active),
    .same_bit_count    (same_bit_count),
    .processing        (processing),
    .data_out          (data_out),
    .last_bit          (last_bit),
    .update_count      (update_count),
    .count_reset       (count_reset),
    .is_stuff_bit      (is_stuff_bit),
    .is_error          (is_error),
    .stuff_error       (stuff_error)
  );

endmodule

// 状态控制单元 - 管理握手和处理状态
module can_destuff_ctrl_unit (
  input  wire clk,
  input  wire rst_n,
  input  wire data_valid,
  input  wire data_out_ready,
  input  wire destuffing_active,
  input  wire is_stuff_bit,
  input  wire is_error,
  output wire data_ready,
  output reg  data_out_valid,
  output reg  processing
);

  // 输入就绪逻辑 - 当未处理数据或输出端准备接收新数据时就绪
  assign data_ready = !processing || (data_out_valid && data_out_ready);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out_valid <= 1'b0;
      processing <= 1'b0;
    end else begin
      // 当输出被接收时清除valid信号
      if (data_out_valid && data_out_ready) begin
        data_out_valid <= 1'b0;
        processing <= 1'b0;
      end
      
      // 输入数据握手成功
      if (data_valid && data_ready && destuffing_active) begin
        processing <= 1'b1;
        
        if (is_error || is_stuff_bit) begin
          // 错误情况或填充位情况，不设置valid
          processing <= 1'b0;
        end else begin
          // 正常数据位
          data_out_valid <= 1'b1;
        end
      end
    end
  end

endmodule

// 位计数单元 - 跟踪连续相同位数
module can_destuff_counter (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       data_in,
  input  wire       last_bit,
  input  wire       update_count,
  input  wire       count_reset,
  output reg  [2:0] same_bit_count
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      same_bit_count <= 3'b000;
    end else if (count_reset) begin
      same_bit_count <= 3'b000;
    end else if (update_count) begin
      same_bit_count <= (data_in == last_bit) ? same_bit_count + 1'b1 : 3'd0;
    end
  end

endmodule

// 位检测和处理单元 - 执行位去填充和错误检测
module can_destuff_detector (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       data_in,
  input  wire       data_valid,
  input  wire       data_ready,
  input  wire       destuffing_active,
  input  wire [2:0] same_bit_count,
  input  wire       processing,
  output reg        data_out,
  output reg        last_bit,
  output wire       update_count,
  output wire       count_reset,
  output wire       is_stuff_bit,
  output wire       is_error,
  output reg        stuff_error
);

  // 检测信号生成
  assign is_stuff_bit = (same_bit_count == 3'd4) && (data_in != last_bit);
  assign is_error = (same_bit_count == 3'd4) && (data_in == last_bit);
  assign update_count = data_valid && data_ready && destuffing_active;
  assign count_reset = is_stuff_bit || is_error || (data_valid && data_ready && destuffing_active && (data_in != last_bit));

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last_bit <= 1'b0;
      data_out <= 1'b1;
      stuff_error <= 1'b0;
    end else begin
      if (data_valid && data_ready && destuffing_active) begin
        // 更新最后接收的位
        last_bit <= data_in;
        
        // 检测填充错误
        if (is_error) begin
          stuff_error <= 1'b1;
        end
        
        // 更新输出数据 (只在非填充位情况下)
        if (!is_stuff_bit && !is_error) begin
          data_out <= data_in;
        end
      end
    end
  end

endmodule