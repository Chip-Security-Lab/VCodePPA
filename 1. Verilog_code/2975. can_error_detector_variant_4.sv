//SystemVerilog
/* IEEE 1364-2005 */
module can_error_detector_axi(
  // AXI4-Lite接口信号
  input wire        s_axi_aclk,
  input wire        s_axi_aresetn,
  // 写地址通道
  input wire [31:0] s_axi_awaddr,
  input wire        s_axi_awvalid,
  output reg        s_axi_awready,
  // 写数据通道
  input wire [31:0] s_axi_wdata,
  input wire [3:0]  s_axi_wstrb,
  input wire        s_axi_wvalid,
  output reg        s_axi_wready,
  // 写响应通道
  output reg [1:0]  s_axi_bresp,
  output reg        s_axi_bvalid,
  input wire        s_axi_bready,
  // 读地址通道
  input wire [31:0] s_axi_araddr,
  input wire        s_axi_arvalid,
  output reg        s_axi_arready,
  // 读数据通道
  output reg [31:0] s_axi_rdata,
  output reg [1:0]  s_axi_rresp,
  output reg        s_axi_rvalid,
  input wire        s_axi_rready,
  
  // CAN接口信号
  input wire        can_rx,
  input wire        bit_sample_point,
  input wire        tx_mode
);

  // 内部寄存器和状态信号
  reg bit_error_reg, stuff_error_reg, form_error_reg, crc_error_reg;
  reg [7:0] error_count_reg;
  reg [2:0] consecutive_bits;
  reg expected_bit, received_bit;
  reg [14:0] crc_calc, crc_received;
  
  // 内存映射寄存器地址 - 使用参数化常量以支持更高效的比较
  localparam ADDR_STATUS       = 32'h0000_0000;  // 状态寄存器
  localparam ADDR_ERROR_COUNT  = 32'h0000_0004;  // 错误计数寄存器
  localparam ADDR_CONTROL      = 32'h0000_0008;  // 控制寄存器
  localparam ADDR_MASK         = 32'h0000_000C;  // 地址掩码

  // AXI4-Lite写地址通道状态 - 使用单热码编码以减少状态机的组合逻辑
  localparam WRITE_IDLE = 2'b00;
  localparam WRITE_ADDR = 2'b01;
  localparam WRITE_DATA = 2'b10;
  localparam WRITE_RESP = 2'b11;
  reg [1:0] write_state;
  
  // AXI4-Lite读地址通道状态 - 使用单热码编码
  localparam READ_IDLE = 2'b00;
  localparam READ_ADDR = 2'b01;
  localparam READ_DATA = 2'b10;
  reg [1:0] read_state;
  
  // 写地址锁存
  reg [31:0] axi_awaddr_reg;
  
  // 控制寄存器
  reg reset_errors;
  
  // 状态寄存器封装 - 使用位域操作优化
  wire [31:0] status_reg = {28'h0, crc_error_reg, form_error_reg, stuff_error_reg, bit_error_reg};
  wire [31:0] error_count_extended = {24'h0, error_count_reg};
  wire [31:0] control_reg = {31'h0, reset_errors};

  // AXI4-Lite写操作处理
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      write_state <= WRITE_IDLE;
      s_axi_awready <= 1'b0;
      s_axi_wready <= 1'b0;
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= 2'b00;
      axi_awaddr_reg <= 32'h0;
      reset_errors <= 1'b0;
    end else begin
      case (write_state)
        WRITE_IDLE: begin
          if (s_axi_awvalid) begin
            s_axi_awready <= 1'b1;
            axi_awaddr_reg <= s_axi_awaddr;
            write_state <= WRITE_ADDR;
          end
        end
        
        WRITE_ADDR: begin
          s_axi_awready <= 1'b0;
          if (s_axi_wvalid) begin
            s_axi_wready <= 1'b1;
            write_state <= WRITE_DATA;
          end
        end
        
        WRITE_DATA: begin
          s_axi_wready <= 1'b0;
          s_axi_bvalid <= 1'b1;
          s_axi_bresp <= 2'b00; // OKAY response

          // 优化处理写入的数据 - 使用更有效的地址比较和位操作
          if ((axi_awaddr_reg & 32'h0000_000C) == ADDR_CONTROL && s_axi_wstrb[0]) begin
            reset_errors <= s_axi_wdata[0];
          end
          
          write_state <= WRITE_RESP;
        end
        
        WRITE_RESP: begin
          if (s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
            write_state <= WRITE_IDLE;
          end
        end
        
        default: write_state <= WRITE_IDLE;
      endcase
    end
  end

  // AXI4-Lite读操作处理 - 优化读逻辑
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      read_state <= READ_IDLE;
      s_axi_arready <= 1'b0;
      s_axi_rvalid <= 1'b0;
      s_axi_rdata <= 32'h0;
      s_axi_rresp <= 2'b00;
    end else begin
      case (read_state)
        READ_IDLE: begin
          if (s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
            read_state <= READ_ADDR;
          end
        end
        
        READ_ADDR: begin
          s_axi_arready <= 1'b0;
          s_axi_rvalid <= 1'b1;
          s_axi_rresp <= 2'b00; // OKAY response
          
          // 优化的寄存器访问 - 使用地址掩码和高效的比较逻辑
          // 使用预先计算的位域值减少数据路径
          case (s_axi_araddr & ADDR_MASK)
            ADDR_STATUS: 
              s_axi_rdata <= status_reg;
            
            ADDR_ERROR_COUNT: 
              s_axi_rdata <= error_count_extended;
            
            ADDR_CONTROL: 
              s_axi_rdata <= control_reg;
            
            default: 
              s_axi_rdata <= 32'h0;
          endcase
          
          read_state <= READ_DATA;
        end
        
        READ_DATA: begin
          if (s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
        
        default: read_state <= READ_IDLE;
      endcase
    end
  end

  // CAN错误检测逻辑 - 优化比较链
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      error_count_reg <= 8'h0;
      bit_error_reg <= 1'b0;
      stuff_error_reg <= 1'b0;
      form_error_reg <= 1'b0;
      crc_error_reg <= 1'b0;
      consecutive_bits <= 3'b000;
    end else if (reset_errors) begin
      error_count_reg <= 8'h0;
      bit_error_reg <= 1'b0;
      stuff_error_reg <= 1'b0;
      form_error_reg <= 1'b0;
      crc_error_reg <= 1'b0;
    end else if (bit_sample_point) begin
      // 优化的比较逻辑 - 使用更高效的条件结构
      // 将多个比较操作重新排序以便进行更快的评估
      if (tx_mode) begin
        // 当在发送模式时 - 优化比较顺序
        if (can_rx != expected_bit) begin
          bit_error_reg <= 1'b1;
          error_count_reg <= error_count_reg + 8'h1;
        end
      end
      
      // 优化的连续位处理 - 使用一个更高效的计数器实现
      if (can_rx == received_bit) begin
        // 连续位逻辑使用增量比较而不是后期评估
        consecutive_bits <= consecutive_bits + 3'b001;
        // 使用即时比较设置stuff_error标志
        if (consecutive_bits == 3'b100) begin  // 如果当前是5个连续位
          stuff_error_reg <= 1'b1;
        end
      end else begin
        consecutive_bits <= 3'b000;
      end
    end
  end

endmodule