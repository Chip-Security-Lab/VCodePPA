//SystemVerilog
module fsm_parity_gen(
  input clk, rst,
  input [15:0] data_in,
  input ready,
  output reg valid,
  output reg parity_bit
);

  localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;
  reg [1:0] state;
  reg [3:0] bit_pos;
  reg data_valid;
  reg [15:0] data_latch;  // 新增数据锁存寄存器
  
  // 状态机状态更新
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (data_valid) begin
            state <= COMPUTE;
          end
        end
        COMPUTE: begin
          if (bit_pos == 4'd15) begin
            state <= DONE;
          end
        end
        DONE: begin
          if (ready) begin
            state <= IDLE;
          end
        end
      endcase
    end
  end

  // 数据有效标志和锁存
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_valid <= 1'b0;
      data_latch <= 16'd0;
    end else if (state == IDLE && !data_valid) begin
      data_valid <= 1'b1;
      data_latch <= data_in;
    end else if (state == DONE && ready) begin
      data_valid <= 1'b0;
    end
  end

  // 位位置计数
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      bit_pos <= 4'd0;
    end else if (state == IDLE && data_valid) begin
      bit_pos <= 4'd0;
    end else if (state == COMPUTE && bit_pos < 4'd15) begin
      bit_pos <= bit_pos + 1'd1;
    end
  end

  // 奇偶校验位计算
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      parity_bit <= 1'b0;
    end else if (state == IDLE && data_valid) begin
      parity_bit <= 1'b0;
    end else if (state == COMPUTE) begin
      parity_bit <= parity_bit ^ data_latch[bit_pos];
    end
  end

  // 有效信号控制
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid <= 1'b0;
    end else if (state == COMPUTE && bit_pos == 4'd15) begin
      valid <= 1'b1;
    end else if (state == DONE && ready) begin
      valid <= 1'b0;
    end
  end

endmodule