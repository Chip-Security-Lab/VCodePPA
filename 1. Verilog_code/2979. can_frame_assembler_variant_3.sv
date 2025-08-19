//SystemVerilog
module can_frame_assembler(
  input wire s_axi_aclk,
  input wire s_axi_aresetn,
  
  // AXI4-Lite写地址通道
  input wire [31:0] s_axi_awaddr,
  input wire [2:0] s_axi_awprot,
  input wire s_axi_awvalid,
  output reg s_axi_awready,
  
  // AXI4-Lite写数据通道
  input wire [31:0] s_axi_wdata,
  input wire [3:0] s_axi_wstrb,
  input wire s_axi_wvalid,
  output reg s_axi_wready,
  
  // AXI4-Lite写响应通道
  output reg [1:0] s_axi_bresp,
  output reg s_axi_bvalid,
  input wire s_axi_bready,
  
  // AXI4-Lite读地址通道
  input wire [31:0] s_axi_araddr,
  input wire [2:0] s_axi_arprot,
  input wire s_axi_arvalid,
  output reg s_axi_arready,
  
  // AXI4-Lite读数据通道
  output reg [31:0] s_axi_rdata,
  output reg [1:0] s_axi_rresp,
  output reg s_axi_rvalid,
  input wire s_axi_rready,
  
  // 输出信号
  output reg [127:0] frame,
  output reg frame_ready
);

  // 内部寄存器
  reg [10:0] id_reg;
  reg [7:0] data_reg [0:7];
  reg [3:0] dlc_reg;
  reg rtr_reg, ide_reg, assemble_reg;
  reg [7:0] state;
  reg [14:0] crc;
  
  // 地址解码参数
  localparam ADDR_ID = 4'h0;
  localparam ADDR_DATA0 = 4'h1;
  localparam ADDR_DATA1 = 4'h2;
  localparam ADDR_DATA2 = 4'h3;
  localparam ADDR_DATA3 = 4'h4;
  localparam ADDR_DATA4 = 4'h5;
  localparam ADDR_DATA5 = 4'h6;
  localparam ADDR_DATA6 = 4'h7;
  localparam ADDR_DATA7 = 4'h8;
  localparam ADDR_CONTROL = 4'h9;
  localparam ADDR_STATUS = 4'hA;
  
  // 优化的地址范围判断
  wire is_data_addr = (write_addr >= ADDR_DATA0) && (write_addr <= ADDR_DATA7);
  wire [2:0] data_index = write_addr[2:0];
  
  // AXI写地址通道处理 - 优化逻辑
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
    end else begin
      s_axi_awready <= ~s_axi_awready & s_axi_awvalid;
    end
  end
  
  // AXI写数据通道处理 - 优化逻辑
  reg [3:0] write_addr;
  reg write_en;
  
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_wready <= 1'b0;
      write_en <= 1'b0;
      write_addr <= 4'h0;
    end else begin
      if (s_axi_awready && s_axi_awvalid) begin
        s_axi_wready <= 1'b1;
        write_addr <= s_axi_awaddr[5:2];
      end else if (s_axi_wready && s_axi_wvalid) begin
        s_axi_wready <= 1'b0;
        write_en <= 1'b1;
      end else begin
        write_en <= 1'b0;
      end
    end
  end
  
  // 寄存器写入 - 优化的比较结构
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      id_reg <= 11'h0;
      dlc_reg <= 4'h0;
      rtr_reg <= 1'b0;
      ide_reg <= 1'b0;
      assemble_reg <= 1'b0;
      data_reg[0] <= 8'h0;
      data_reg[1] <= 8'h0;
      data_reg[2] <= 8'h0;
      data_reg[3] <= 8'h0;
      data_reg[4] <= 8'h0;
      data_reg[5] <= 8'h0;
      data_reg[6] <= 8'h0;
      data_reg[7] <= 8'h0;
    end else begin
      // 自动清除assemble标志
      assemble_reg <= (write_en && s_axi_wstrb[0] && write_addr == ADDR_CONTROL) ? 
                      s_axi_wdata[6] : 1'b0;
      
      if (write_en && s_axi_wstrb[0]) begin
        if (is_data_addr) begin
          // 优化的数据写入逻辑，使用索引而不是多个比较
          data_reg[data_index] <= s_axi_wdata[7:0];
        end else begin
          // 根据地址写入非数据寄存器
          case (write_addr)
            ADDR_ID: id_reg <= s_axi_wdata[10:0];
            ADDR_CONTROL: begin
              dlc_reg <= s_axi_wdata[3:0];
              rtr_reg <= s_axi_wdata[4];
              ide_reg <= s_axi_wdata[5];
              // assemble_reg在上面已经处理
            end
            default: begin end
          endcase
        end
      end
    end
  end
  
  // 写响应通道 - 优化逻辑
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_bvalid <= 1'b0;
      s_axi_bresp <= 2'b0;
    end else begin
      if (s_axi_wready && s_axi_wvalid) begin
        s_axi_bvalid <= 1'b1;
        s_axi_bresp <= 2'b00; // OKAY响应
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end
  
  // AXI读地址通道处理 - 优化逻辑
  reg [3:0] read_addr;
  
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b0;
      read_addr <= 4'h0;
    end else begin
      s_axi_arready <= ~s_axi_arready & s_axi_arvalid;
      if (~s_axi_arready && s_axi_arvalid) begin
        read_addr <= s_axi_araddr[5:2];
      end
    end
  end
  
  // 读数据选择 - 优化的多路复用器
  reg [31:0] read_data;
  wire is_read_data_addr = (read_addr >= ADDR_DATA0) && (read_addr <= ADDR_DATA7);
  wire [2:0] read_data_index = read_addr[2:0];
  
  always @(*) begin
    if (is_read_data_addr) begin
      read_data = {24'h0, data_reg[read_data_index]};
    end else begin
      case (read_addr)
        ADDR_ID:      read_data = {21'h0, id_reg};
        ADDR_CONTROL: read_data = {25'h0, assemble_reg, ide_reg, rtr_reg, dlc_reg};
        ADDR_STATUS:  read_data = {31'h0, frame_ready};
        default:      read_data = 32'h0;
      endcase
    end
  end
  
  // AXI读数据通道处理 - 优化逻辑
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rdata <= 32'h0;
      s_axi_rresp <= 2'b0;
    end else begin
      if (s_axi_arready && s_axi_arvalid) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rresp <= 2'b00; // OKAY响应
        s_axi_rdata <= read_data;
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end
  
  // CAN帧组装逻辑 - 优化数据装载
  reg [63:0] data_field;
  
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      frame <= 128'h0;
      frame_ready <= 1'b0;
      data_field <= 64'h0;
    end else begin
      // 预先组装数据字段以避免在主逻辑中进行级联
      data_field <= {data_reg[0], data_reg[1], data_reg[2], data_reg[3],
                     data_reg[4], data_reg[5], data_reg[6], data_reg[7]};
      
      if (assemble_reg) begin
        // 紧凑的帧装配
        frame <= {45'h0,
                 (rtr_reg ? 64'h0 : data_field),   // 数据字段 (0-8 bytes)
                 dlc_reg,                           // DLC (4 bits)
                 1'b0,                              // r0 预留位
                 ide_reg,                           // IDE 位
                 rtr_reg,                           // RTR 位
                 id_reg,                            // 标识符 (11 bits)
                 1'b0};                             // SOF (1 bit)
        frame_ready <= 1'b1;
      end
    end
  end

endmodule