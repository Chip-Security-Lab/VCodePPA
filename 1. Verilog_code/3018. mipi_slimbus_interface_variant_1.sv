//SystemVerilog
module mipi_slimbus_interface (
  input wire s_axi_aclk,
  input wire s_axi_aresetn,
  
  // AXI4-Lite接口 - 写地址通道
  input wire [31:0] s_axi_awaddr,
  input wire s_axi_awvalid,
  output reg s_axi_awready,
  
  // AXI4-Lite接口 - 写数据通道
  input wire [31:0] s_axi_wdata,
  input wire [3:0] s_axi_wstrb,
  input wire s_axi_wvalid,
  output reg s_axi_wready,
  
  // AXI4-Lite接口 - 写响应通道
  output reg [1:0] s_axi_bresp,
  output reg s_axi_bvalid,
  input wire s_axi_bready,
  
  // AXI4-Lite接口 - 读地址通道
  input wire [31:0] s_axi_araddr,
  input wire s_axi_arvalid,
  output reg s_axi_arready,
  
  // AXI4-Lite接口 - 读数据通道
  output reg [31:0] s_axi_rdata,
  output reg [1:0] s_axi_rresp,
  output reg s_axi_rvalid,
  input wire s_axi_rready,
  
  // MIPI接口信号
  input wire data_in, clock_in,
  output reg data_out, frame_sync
);

  // MIPI内部状态和寄存器
  localparam SYNC = 2'b00, HEADER = 2'b01, DATA = 2'b10, CRC = 2'b11;
  
  // 内部寄存器定义
  reg [1:0] state;
  reg [7:0] bit_counter;
  reg [9:0] frame_counter;
  reg [31:0] received_data;
  reg data_valid;
  reg [7:0] device_id;
  
  // AXI4-Lite寄存器地址映射
  localparam CTRL_REG_ADDR     = 4'h0;    // 控制寄存器 (device_id)
  localparam STATUS_REG_ADDR   = 4'h4;    // 状态寄存器 (data_valid)
  localparam DATA_REG_ADDR     = 4'h8;    // 数据寄存器 (received_data)
  
  // AXI4-Lite写状态机
  localparam AXI_IDLE = 2'b00;
  localparam AXI_WRITE_ADDR = 2'b01;
  localparam AXI_WRITE_DATA = 2'b10;
  localparam AXI_WRITE_RESP = 2'b11;
  
  // AXI4-Lite读状态机
  localparam AXI_READ_ADDR = 2'b01;
  localparam AXI_READ_DATA = 2'b10;
  
  reg [1:0] axi_write_state;
  reg [1:0] axi_read_state;
  reg [3:0] write_addr;
  reg [3:0] read_addr;
  
  // AXI4-Lite写状态机
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      axi_write_state <= AXI_IDLE;
      s_axi_awready <= 1'b0;
      s_axi_wready <= 1'b0;
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= 2'b00;
      write_addr <= 4'h0;
      device_id <= 8'h00;
    end else begin
      case (axi_write_state)
        AXI_IDLE: begin
          if (s_axi_awvalid) begin
            axi_write_state <= AXI_WRITE_ADDR;
            s_axi_awready <= 1'b1;
            write_addr <= s_axi_awaddr[3:0];
          end
        end
        
        AXI_WRITE_ADDR: begin
          s_axi_awready <= 1'b0;
          if (s_axi_wvalid) begin
            axi_write_state <= AXI_WRITE_DATA;
            s_axi_wready <= 1'b1;
            
            // 只有控制寄存器是可写的
            if (write_addr == CTRL_REG_ADDR) begin
              device_id <= s_axi_wdata[7:0];
              s_axi_bresp <= 2'b00; // OKAY
            end else begin
              s_axi_bresp <= 2'b10; // SLVERR - 不支持写入的地址
            end
          end
        end
        
        AXI_WRITE_DATA: begin
          s_axi_wready <= 1'b0;
          axi_write_state <= AXI_WRITE_RESP;
          s_axi_bvalid <= 1'b1;
        end
        
        AXI_WRITE_RESP: begin
          if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            axi_write_state <= AXI_IDLE;
          end
        end
      endcase
    end
  end
  
  // AXI4-Lite读状态机
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      axi_read_state <= AXI_IDLE;
      s_axi_arready <= 1'b0;
      s_axi_rvalid <= 1'b0;
      s_axi_rresp <= 2'b00;
      read_addr <= 4'h0;
    end else begin
      case (axi_read_state)
        AXI_IDLE: begin
          if (s_axi_arvalid) begin
            axi_read_state <= AXI_READ_ADDR;
            s_axi_arready <= 1'b1;
            read_addr <= s_axi_araddr[3:0];
          end
        end
        
        AXI_READ_ADDR: begin
          s_axi_arready <= 1'b0;
          axi_read_state <= AXI_READ_DATA;
          s_axi_rvalid <= 1'b1;
          
          // 根据地址选择要读取的寄存器
          case (read_addr)
            CTRL_REG_ADDR: begin
              s_axi_rdata <= {24'h0, device_id};
              s_axi_rresp <= 2'b00; // OKAY
            end
            STATUS_REG_ADDR: begin
              s_axi_rdata <= {31'h0, data_valid};
              s_axi_rresp <= 2'b00; // OKAY
            end
            DATA_REG_ADDR: begin
              s_axi_rdata <= received_data;
              s_axi_rresp <= 2'b00; // OKAY
            end
            default: begin
              s_axi_rdata <= 32'h0;
              s_axi_rresp <= 2'b10; // SLVERR - 不支持读取的地址
            end
          endcase
        end
        
        AXI_READ_DATA: begin
          if (s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            axi_read_state <= AXI_IDLE;
          end
        end
      endcase
    end
  end
  
  // MIPI Slimbus处理逻辑 - 保持核心功能不变
  always @(posedge clock_in or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      state <= SYNC;
      bit_counter <= 8'd0;
      frame_counter <= 10'd0;
      data_valid <= 1'b0;
      received_data <= 32'd0;
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
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      data_out <= 1'b0;
    end else if (state == DATA) begin
      data_out <= received_data[31]; // 回发最高位数据
    end else begin
      data_out <= 1'b0;
    end
  end

endmodule