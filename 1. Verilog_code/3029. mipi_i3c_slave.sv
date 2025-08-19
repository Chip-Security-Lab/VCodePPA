module mipi_i3c_slave #(parameter ADDR = 7'h27) (
  input wire scl, reset_n,
  inout wire sda,
  output reg [7:0] rx_data,
  output reg new_data,
  input wire [7:0] tx_data,
  output reg busy
);
  localparam IDLE = 3'd0, ADDRESS = 3'd1, ACK_ADDR = 3'd2;
  localparam RX = 3'd3, TX = 3'd4, ACK_DATA = 3'd5;
  
  reg [2:0] state;
  reg [7:0] shift_reg;
  reg [3:0] bit_count;
  reg sda_out, sda_oe;
  reg direction; // 0=接收, 1=发送
  
  // SDA是双向的
  assign sda = sda_oe ? sda_out : 1'bz;
  
  // 开始条件检测
  reg sda_prev;
  reg scl_high;
  wire start_cond = scl_high && sda_prev && !sda;
  wire stop_cond = scl_high && !sda_prev && sda;
  
  always @(negedge scl or negedge reset_n) begin
    if (!reset_n) begin
      sda_prev <= 1'b1;
      scl_high <= 1'b0;
    end else begin
      sda_prev <= sda;
      scl_high <= 1'b1;
    end
  end
  
  always @(posedge scl or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      sda_oe <= 1'b0;
      new_data <= 1'b0;
      busy <= 1'b0;
      shift_reg <= 8'h00;
      bit_count <= 4'd0;
      direction <= 1'b0;
      rx_data <= 8'h00;
    end else begin
      case (state)
        IDLE: begin
          if (start_cond) begin
            state <= ADDRESS;
            bit_count <= 4'd0;
            busy <= 1'b1;
          end
        end
        
        ADDRESS: begin
          shift_reg <= {shift_reg[6:0], sda};
          bit_count <= bit_count + 1'b1;
          if (bit_count == 4'd7) begin
            state <= ACK_ADDR;
            direction <= sda; // 最低位为读/写
          end
        end
        
        ACK_ADDR: begin
          if (shift_reg[7:1] == ADDR) begin
            sda_oe <= 1'b1;
            sda_out <= 1'b0; // ACK
            state <= direction ? TX : RX;
            bit_count <= 4'd0;
            rx_data <= 8'h00;
          end else begin
            sda_oe <= 1'b0; // NACK
            state <= IDLE;
            busy <= 1'b0;
          end
        end
        
        RX: begin
          sda_oe <= 1'b0;
          rx_data <= {rx_data[6:0], sda};
          bit_count <= bit_count + 1'b1;
          if (bit_count == 4'd7) begin
            state <= ACK_DATA;
            new_data <= 1'b1; // 标记新数据
          end
        end
        
        TX: begin
          sda_oe <= 1'b1;
          sda_out <= tx_data[7-bit_count];
          bit_count <= bit_count + 1'b1;
          if (bit_count == 4'd7) begin
            state <= ACK_DATA;
          end
        end
        
        ACK_DATA: begin
          if (direction) begin // TX模式
            sda_oe <= 1'b0; // 释放SDA查看主机ACK
            if (sda == 1'b1) begin // NACK
              state <= IDLE;
              busy <= 1'b0;
            end else begin
              state <= TX;
              bit_count <= 4'd0;
            end
          end else begin // RX模式
            sda_oe <= 1'b1;
            sda_out <= 1'b0; // 发送ACK
            state <= RX;
            bit_count <= 4'd0;
            new_data <= 1'b0;
          end
        end
        
        default: begin
          state <= IDLE;
        end
      endcase
      
      // 检测停止条件
      if (stop_cond) begin
        state <= IDLE;
        busy <= 1'b0;
        sda_oe <= 1'b0;
      end
    end
  end
endmodule