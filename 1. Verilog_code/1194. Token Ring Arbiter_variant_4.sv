//SystemVerilog
module token_ring_arbiter_axi4lite (
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  
  // AXI4-Lite 写地址通道
  input  wire [31:0] s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output wire        s_axi_awready,
  
  // AXI4-Lite 写数据通道
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output wire        s_axi_wready,
  
  // AXI4-Lite 写响应通道
  output wire [1:0]  s_axi_bresp,
  output wire        s_axi_bvalid,
  input  wire        s_axi_bready,
  
  // AXI4-Lite 读地址通道
  input  wire [31:0] s_axi_araddr,
  input  wire        s_axi_arvalid,
  output wire        s_axi_arready,
  
  // AXI4-Lite 读数据通道
  output wire [31:0] s_axi_rdata,
  output wire [1:0]  s_axi_rresp,
  output wire        s_axi_rvalid,
  input  wire        s_axi_rready,
  
  // 仲裁器接口输出
  output wire [3:0]  grant,
  output wire [1:0]  token
);

  // 内部寄存器
  reg [3:0]  req_reg;
  reg [3:0]  grant_reg;
  reg [1:0]  token_reg;
  
  // AXI4-Lite 接口控制信号
  reg        write_active;
  reg        read_active;
  reg [31:0] read_data;
  reg        write_ready;
  reg        read_valid;
  
  // 地址寄存器和控制寄存器
  reg [31:0] awaddr_reg;
  reg [31:0] araddr_reg;
  
  // 令牌环仲裁器核心逻辑信号
  reg [3:0]  req_priority;
  reg        update_token;
  reg [1:0]  next_token;
  
  // 寄存器地址映射 (基地址 0x0000_0000)
  localparam REG_REQ_ADDR   = 8'h00; // 请求寄存器地址
  localparam REG_GRANT_ADDR = 8'h04; // 授权寄存器地址
  localparam REG_TOKEN_ADDR = 8'h08; // 令牌寄存器地址
  
  // AXI4-Lite 写地址通道控制
  assign s_axi_awready = ~write_active;
  
  // AXI4-Lite 写数据通道控制
  assign s_axi_wready = write_active & ~write_ready;
  
  // AXI4-Lite 写响应通道控制
  assign s_axi_bresp = 2'b00; // OKAY
  assign s_axi_bvalid = write_ready;
  
  // AXI4-Lite 读地址通道控制
  assign s_axi_arready = ~read_active;
  
  // AXI4-Lite 读数据通道控制
  assign s_axi_rdata = read_data;
  assign s_axi_rresp = 2'b00; // OKAY
  assign s_axi_rvalid = read_valid;
  
  // 模块输出
  assign grant = grant_reg;
  assign token = token_reg;
  
  // 写地址和写数据处理
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      write_active <= 1'b0;
      write_ready <= 1'b0;
      awaddr_reg <= 32'h0;
      req_reg <= 4'h0;
    end else begin
      // 写地址通道握手
      if (s_axi_awvalid && s_axi_awready) begin
        awaddr_reg <= s_axi_awaddr;
        write_active <= 1'b1;
      end
      
      // 写数据通道握手
      if (write_active && s_axi_wvalid && s_axi_wready) begin
        case (awaddr_reg[7:0])
          REG_REQ_ADDR: begin
            if (s_axi_wstrb[0]) req_reg <= s_axi_wdata[3:0];
          end
          default: begin
            // 其他地址为只读
          end
        endcase
        write_ready <= 1'b1;
      end
      
      // 写响应通道握手
      if (write_ready && s_axi_bready) begin
        write_ready <= 1'b0;
        write_active <= 1'b0;
      end
    end
  end
  
  // 读地址和读数据处理
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      read_active <= 1'b0;
      read_valid <= 1'b0;
      araddr_reg <= 32'h0;
      read_data <= 32'h0;
    end else begin
      // 读地址通道握手
      if (s_axi_arvalid && s_axi_arready) begin
        araddr_reg <= s_axi_araddr;
        read_active <= 1'b1;
      end
      
      // 读数据通道处理
      if (read_active && ~read_valid) begin
        case (araddr_reg[7:0])
          REG_REQ_ADDR: read_data <= {28'h0, req_reg};
          REG_GRANT_ADDR: read_data <= {28'h0, grant_reg};
          REG_TOKEN_ADDR: read_data <= {30'h0, token_reg};
          default: read_data <= 32'h0;
        endcase
        read_valid <= 1'b1;
      end
      
      // 读数据通道握手
      if (read_valid && s_axi_rready) begin
        read_valid <= 1'b0;
        read_active <= 1'b0;
      end
    end
  end
  
  // 令牌环仲裁器核心逻辑 - 同步逻辑
  always @(posedge s_axi_aclk) begin
    if (~s_axi_aresetn) begin
      token_reg <= 2'd0;
      grant_reg <= 4'd0;
    end else begin
      grant_reg <= req_priority;
      if (update_token) begin
        token_reg <= next_token;
      end
    end
  end

  // 令牌环仲裁器核心逻辑 - 组合逻辑
  always @(*) begin
    // 默认值
    req_priority = 4'd0;
    update_token = 1'b0;
    next_token = token_reg;

    // 使用轮转优先级检查，优化比较链
    case (token_reg)
      2'd0: begin
        if (req_reg[0]) begin
          req_priority[0] = 1'b1;
        end else if (|req_reg[3:1]) begin
          if (req_reg[1]) begin
            req_priority[1] = 1'b1;
            next_token = 2'd1;
          end else if (req_reg[2]) begin
            req_priority[2] = 1'b1;
            next_token = 2'd2;
          end else begin // req_reg[3] 必定为真
            req_priority[3] = 1'b1;
            next_token = 2'd3;
          end
          update_token = 1'b1;
        end
      end

      2'd1: begin
        if (req_reg[1]) begin
          req_priority[1] = 1'b1;
        end else if (req_reg[2] || req_reg[3] || req_reg[0]) begin
          if (req_reg[2]) begin
            req_priority[2] = 1'b1;
            next_token = 2'd2;
          end else if (req_reg[3]) begin
            req_priority[3] = 1'b1;
            next_token = 2'd3;
          end else begin // req_reg[0] 必定为真
            req_priority[0] = 1'b1;
            next_token = 2'd0;
          end
          update_token = 1'b1;
        end
      end

      2'd2: begin
        if (req_reg[2]) begin
          req_priority[2] = 1'b1;
        end else if (req_reg[3] || req_reg[0] || req_reg[1]) begin
          if (req_reg[3]) begin
            req_priority[3] = 1'b1;
            next_token = 2'd3;
          end else if (req_reg[0]) begin
            req_priority[0] = 1'b1;
            next_token = 2'd0;
          end else begin // req_reg[1] 必定为真
            req_priority[1] = 1'b1;
            next_token = 2'd1;
          end
          update_token = 1'b1;
        end
      end

      2'd3: begin
        if (req_reg[3]) begin
          req_priority[3] = 1'b1;
        end else if (|req_reg[2:0]) begin
          if (req_reg[0]) begin
            req_priority[0] = 1'b1;
            next_token = 2'd0;
          end else if (req_reg[1]) begin
            req_priority[1] = 1'b1;
            next_token = 2'd1;
          end else begin // req_reg[2] 必定为真
            req_priority[2] = 1'b1;
            next_token = 2'd2;
          end
          update_token = 1'b1;
        end
      end
    endcase
  end
endmodule