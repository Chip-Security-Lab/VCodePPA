module mipi_slimbus_interface (
  input wire clk, reset_n,
  input wire data_in, clock_in,
  input wire [7:0] device_id,
  output reg data_out, frame_sync,
  output reg [31:0] received_data,
  output reg data_valid
);
  localparam SYNC = 2'b00, HEADER = 2'b01, DATA = 2'b10, CRC = 2'b11;
  reg [1:0] state;
  reg [7:0] bit_counter;
  reg [9:0] frame_counter;
  
  always @(posedge clock_in or negedge reset_n) begin
    if (!reset_n) begin
      state <= SYNC;
      bit_counter <= 8'd0;
      frame_counter <= 10'd0;
      data_valid <= 1'b0;
      received_data <= 32'd0;
      data_out <= 1'b0;
      frame_sync <= 1'b0;
    end else begin
      case (state)
        SYNC: begin
          data_valid <= 1'b0;
          if (data_in && frame_counter == 10'd511) begin
            state <= HEADER;
            frame_sync <= 1'b1;
          end else begin
            frame_sync <= 1'b0;
          end
        end
        
        HEADER: begin
          frame_sync <= 1'b0;
          if (bit_counter < 8'd15) begin
            bit_counter <= bit_counter + 1'b1;
            // 解析头部
            if (bit_counter < 8) begin
              // 检查设备ID匹配
              if (bit_counter == 7 && received_data[7:0] != device_id) begin
                state <= SYNC; // 不匹配则返回SYNC状态
                bit_counter <= 8'd0;
              end
            end
          end else begin
            bit_counter <= 8'd0;
            state <= DATA;
          end
        end
        
        DATA: begin
          if (bit_counter < 8'd31) begin
            bit_counter <= bit_counter + 1'b1;
            received_data <= {received_data[30:0], data_in};
          end else begin
            bit_counter <= 8'd0;
            state <= CRC;
          end
        end
        
        CRC: begin
          if (bit_counter < 8'd7) begin
            bit_counter <= bit_counter + 1'b1;
            // 简化CRC检查
            if (bit_counter == 7) begin
              data_valid <= 1'b1; // 数据有效
              state <= SYNC;
            end
          end else begin
            bit_counter <= 8'd0;
            state <= SYNC;
          end
        end
        
        default: begin
          state <= SYNC;
        end
      endcase
      
      // 帧计数器管理
      frame_counter <= (frame_counter == 10'd511) ? 10'd0 : frame_counter + 1'b1;
    end
  end
  
  // 数据输出逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_out <= 1'b0;
    end else if (state == DATA) begin
      data_out <= received_data[31]; // 回发最高位数据
    end else begin
      data_out <= 1'b0;
    end
  end
endmodule