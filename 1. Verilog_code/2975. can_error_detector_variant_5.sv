//SystemVerilog

// 顶层模块 - 转换为AXI4-Lite接口
module can_error_detector (
  // 全局信号
  input wire s_axi_aclk,
  input wire s_axi_aresetn,
  
  // AXI4-Lite写地址通道
  input wire [31:0] s_axi_awaddr,
  input wire [2:0] s_axi_awprot,
  input wire s_axi_awvalid,
  output wire s_axi_awready,
  
  // AXI4-Lite写数据通道
  input wire [31:0] s_axi_wdata,
  input wire [3:0] s_axi_wstrb,
  input wire s_axi_wvalid,
  output wire s_axi_wready,
  
  // AXI4-Lite写响应通道
  output wire [1:0] s_axi_bresp,
  output wire s_axi_bvalid,
  input wire s_axi_bready,
  
  // AXI4-Lite读地址通道
  input wire [31:0] s_axi_araddr,
  input wire [2:0] s_axi_arprot,
  input wire s_axi_arvalid,
  output wire s_axi_arready,
  
  // AXI4-Lite读数据通道
  output wire [31:0] s_axi_rdata,
  output wire [1:0] s_axi_rresp,
  output wire s_axi_rvalid,
  input wire s_axi_rready,
  
  // CAN接口信号
  input wire can_rx,
  input wire bit_sample_point,
  output wire bit_error, stuff_error, form_error, crc_error,
  output wire [7:0] error_count
);

  // 内部连线
  wire clk;
  wire rst_n;
  wire bit_sample_pulse;
  wire [2:0] consecutive_bits;
  wire expected_bit;
  wire received_bit;
  wire tx_mode;
  
  // 寄存器映射 (基地址偏移量)
  localparam CTRL_REG       = 5'h00; // 控制寄存器
  localparam STATUS_REG     = 5'h04; // 状态寄存器
  localparam ERROR_COUNT_REG = 5'h08; // 错误计数寄存器
  
  // 内部寄存器
  reg [31:0] ctrl_reg;
  reg [31:0] status_reg;
  
  // AXI4-Lite接口控制寄存器
  reg s_axi_awready_reg;
  reg s_axi_wready_reg;
  reg [1:0] s_axi_bresp_reg;
  reg s_axi_bvalid_reg;
  reg s_axi_arready_reg;
  reg [31:0] s_axi_rdata_reg;
  reg [1:0] s_axi_rresp_reg;
  reg s_axi_rvalid_reg;
  
  // 地址解码寄存器
  reg [4:0] write_addr;
  reg [4:0] read_addr;
  reg write_enable;
  reg read_enable;
  
  // 信号映射
  assign clk = s_axi_aclk;
  assign rst_n = s_axi_aresetn;
  assign tx_mode = ctrl_reg[0];  // 控制寄存器的第0位用于tx_mode
  
  // AXI4-Lite输出分配
  assign s_axi_awready = s_axi_awready_reg;
  assign s_axi_wready = s_axi_wready_reg;
  assign s_axi_bresp = s_axi_bresp_reg;
  assign s_axi_bvalid = s_axi_bvalid_reg;
  assign s_axi_arready = s_axi_arready_reg;
  assign s_axi_rdata = s_axi_rdata_reg;
  assign s_axi_rresp = s_axi_rresp_reg;
  assign s_axi_rvalid = s_axi_rvalid_reg;
  
  // 写地址通道处理
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_awready_reg <= 1'b0;
      write_addr <= 5'h0;
      write_enable <= 1'b0;
    end else begin
      if (s_axi_awvalid && !s_axi_awready_reg) begin
        s_axi_awready_reg <= 1'b1;
        write_addr <= s_axi_awaddr[6:2]; // 4字节对齐
        write_enable <= 1'b1;
      end else begin
        s_axi_awready_reg <= 1'b0;
        write_enable <= 1'b0;
      end
    end
  end
  
  // 写数据通道处理
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_wready_reg <= 1'b0;
      ctrl_reg <= 32'h0;
    end else begin
      if (s_axi_wvalid && write_enable && !s_axi_wready_reg) begin
        s_axi_wready_reg <= 1'b1;
        
        // 寄存器写入处理
        case (write_addr)
          CTRL_REG: begin
            if (s_axi_wstrb[0]) ctrl_reg[7:0] <= s_axi_wdata[7:0];
            if (s_axi_wstrb[1]) ctrl_reg[15:8] <= s_axi_wdata[15:8];
            if (s_axi_wstrb[2]) ctrl_reg[23:16] <= s_axi_wdata[23:16];
            if (s_axi_wstrb[3]) ctrl_reg[31:24] <= s_axi_wdata[31:24];
          end
          default: ; // 其他地址不可写
        endcase
      end else begin
        s_axi_wready_reg <= 1'b0;
      end
    end
  end
  
  // 写响应通道处理
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_bvalid_reg <= 1'b0;
      s_axi_bresp_reg <= 2'b00;
    end else begin
      if (s_axi_wready_reg && !s_axi_bvalid_reg) begin
        s_axi_bvalid_reg <= 1'b1;
        s_axi_bresp_reg <= 2'b00; // OKAY
      end else if (s_axi_bvalid_reg && s_axi_bready) begin
        s_axi_bvalid_reg <= 1'b0;
      end
    end
  end
  
  // 读地址通道处理
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_arready_reg <= 1'b0;
      read_addr <= 5'h0;
      read_enable <= 1'b0;
    end else begin
      if (s_axi_arvalid && !s_axi_arready_reg) begin
        s_axi_arready_reg <= 1'b1;
        read_addr <= s_axi_araddr[6:2]; // 4字节对齐
        read_enable <= 1'b1;
      end else begin
        s_axi_arready_reg <= 1'b0;
        read_enable <= 1'b0;
      end
    end
  end
  
  // 读数据通道处理
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_rvalid_reg <= 1'b0;
      s_axi_rresp_reg <= 2'b00;
      s_axi_rdata_reg <= 32'h0;
    end else begin
      if (read_enable && !s_axi_rvalid_reg) begin
        s_axi_rvalid_reg <= 1'b1;
        s_axi_rresp_reg <= 2'b00; // OKAY
        
        // 寄存器读取处理
        case (read_addr)
          CTRL_REG: s_axi_rdata_reg <= ctrl_reg;
          STATUS_REG: s_axi_rdata_reg <= {28'h0, crc_error, form_error, stuff_error, bit_error};
          ERROR_COUNT_REG: s_axi_rdata_reg <= {24'h0, error_count};
          default: s_axi_rdata_reg <= 32'h0;
        endcase
      end else if (s_axi_rvalid_reg && s_axi_rready) begin
        s_axi_rvalid_reg <= 1'b0;
      end
    end
  end
  
  // 状态寄存器更新 - 每个时钟周期更新
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      status_reg <= 32'h0;
    end else begin
      status_reg <= {28'h0, crc_error, form_error, stuff_error, bit_error};
    end
  end
  
  // 子模块实例化
  bit_sampler bit_sampler_inst (
    .clk(clk),
    .rst_n(rst_n),
    .bit_sample_point(bit_sample_point),
    .bit_sample_pulse(bit_sample_pulse)
  );
  
  bit_error_detector bit_error_detect_inst (
    .clk(clk),
    .rst_n(rst_n),
    .can_rx(can_rx),
    .expected_bit(expected_bit),
    .tx_mode(tx_mode),
    .bit_sample_pulse(bit_sample_pulse),
    .bit_error(bit_error)
  );
  
  stuff_error_detector stuff_error_detect_inst (
    .clk(clk),
    .rst_n(rst_n),
    .can_rx(can_rx),
    .received_bit(received_bit),
    .bit_sample_pulse(bit_sample_pulse),
    .consecutive_bits(consecutive_bits),
    .stuff_error(stuff_error)
  );
  
  crc_error_detector crc_error_detect_inst (
    .clk(clk),
    .rst_n(rst_n), 
    .can_rx(can_rx),
    .bit_sample_pulse(bit_sample_pulse),
    .crc_error(crc_error)
  );
  
  form_error_detector form_error_detect_inst (
    .clk(clk),
    .rst_n(rst_n),
    .can_rx(can_rx),
    .bit_sample_pulse(bit_sample_pulse),
    .form_error(form_error)
  );
  
  error_counter error_counter_inst (
    .clk(clk),
    .rst_n(rst_n),
    .bit_error(bit_error),
    .stuff_error(stuff_error),
    .form_error(form_error),
    .crc_error(crc_error),
    .bit_sample_pulse(bit_sample_pulse),
    .error_count(error_count)
  );
  
  bus_state_monitor bus_monitor_inst (
    .clk(clk),
    .rst_n(rst_n),
    .can_rx(can_rx),
    .bit_sample_pulse(bit_sample_pulse),
    .expected_bit(expected_bit),
    .received_bit(received_bit)
  );
  
endmodule

// 采样点检测子模块 - 优化后
module bit_sampler(
  input wire clk, rst_n,
  input wire bit_sample_point,
  output reg bit_sample_pulse
);
  
  // 直接使用bit_sample_point，移除了输入端的寄存器延迟
  assign bit_sample_pulse = bit_sample_point;
  
endmodule

// 位错误检测子模块 - 优化后
module bit_error_detector(
  input wire clk, rst_n,
  input wire can_rx, expected_bit, tx_mode,
  input wire bit_sample_pulse,
  output reg bit_error
);
  
  // 内部信号，用于保存组合逻辑计算结果
  wire error_detected;
  
  // 组合逻辑提前计算错误检测
  assign error_detected = tx_mode && (can_rx != expected_bit);
  
  // 寄存器移到组合逻辑之后
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_error <= 1'b0;
    end else if (bit_sample_pulse) begin
      bit_error <= error_detected;
    end
  end
  
endmodule

// 比特填充错误检测子模块 - 优化后
module stuff_error_detector(
  input wire clk, rst_n,
  input wire can_rx, received_bit,
  input wire bit_sample_pulse,
  output reg [2:0] consecutive_bits,
  output reg stuff_error
);
  
  // 内部信号，用于提前计算
  wire bits_match;
  wire [2:0] next_consecutive_bits;
  wire next_stuff_error;
  
  // 组合逻辑提前计算
  assign bits_match = (can_rx == received_bit);
  assign next_consecutive_bits = bits_match ? consecutive_bits + 1'b1 : 3'b000;
  assign next_stuff_error = (next_consecutive_bits >= 3'b100); // 检测连续5位相同位
  
  // 寄存器移到组合逻辑之后
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      consecutive_bits <= 3'b000;
      stuff_error <= 1'b0;
    end else if (bit_sample_pulse) begin
      consecutive_bits <= next_consecutive_bits;
      stuff_error <= next_stuff_error;
    end
  end
  
endmodule

// CRC错误检测子模块 - 优化后
module crc_error_detector(
  input wire clk, rst_n,
  input wire can_rx,
  input wire bit_sample_pulse,
  output reg crc_error
);
  
  // CRC计算寄存器
  reg [14:0] crc_calc;
  reg [14:0] crc_received;
  
  // 内部组合逻辑信号
  wire [14:0] next_crc_calc;
  
  // CRC计算的组合逻辑部分（简化版本）
  assign next_crc_calc = can_rx ? {crc_calc[13:0], 1'b0} : {crc_calc[13:0], 1'b1};
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_calc <= 15'h0000;
      crc_received <= 15'h0000;
      crc_error <= 1'b0;
    end else if (bit_sample_pulse) begin
      crc_calc <= next_crc_calc;
      // 实际CRC实现逻辑（简化版本）
      crc_error <= 1'b0;
    end
  end
  
endmodule

// 帧格式错误检测子模块 - 优化后
module form_error_detector(
  input wire clk, rst_n,
  input wire can_rx,
  input wire bit_sample_pulse,
  output reg form_error
);
  
  // 前移的组合逻辑信号
  wire form_check;
  
  // 简化的形式检查逻辑
  assign form_check = 1'b0; // 简化实现
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      form_error <= 1'b0;
    end else if (bit_sample_pulse) begin
      form_error <= form_check;
    end
  end
  
endmodule

// 错误计数器子模块 - 优化后
module error_counter(
  input wire clk, rst_n,
  input wire bit_error, stuff_error, form_error, crc_error,
  input wire bit_sample_pulse,
  output reg [7:0] error_count
);
  
  wire any_error;
  wire [7:0] next_error_count;
  
  assign any_error = bit_error | stuff_error | form_error | crc_error;
  assign next_error_count = error_count + 8'h01;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_count <= 8'h00;
    end else if (bit_sample_pulse && any_error) begin
      error_count <= next_error_count;
    end
  end
  
endmodule

// 总线状态监控器 - 优化后
module bus_state_monitor(
  input wire clk, rst_n,
  input wire can_rx,
  input wire bit_sample_pulse,
  output reg expected_bit,
  output reg received_bit
);
  
  // 前移组合逻辑计算
  wire next_received_bit;
  wire next_expected_bit;
  
  assign next_received_bit = can_rx;
  assign next_expected_bit = received_bit; // 简化实现
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      expected_bit <= 1'b0;
      received_bit <= 1'b0;
    end else if (bit_sample_pulse) begin
      received_bit <= next_received_bit;
      expected_bit <= next_expected_bit;
    end
  end
  
endmodule