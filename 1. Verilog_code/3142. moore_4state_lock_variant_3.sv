//SystemVerilog
module moore_4state_lock(
  input  logic        s_axi_aclk,
  input  logic        s_axi_aresetn,
  
  // AXI4-Lite Slave Interface - Write Address Channel
  input  logic        s_axi_awvalid,
  output logic        s_axi_awready,
  input  logic [31:0] s_axi_awaddr,
  input  logic [2:0]  s_axi_awprot,
  
  // AXI4-Lite Slave Interface - Write Data Channel
  input  logic        s_axi_wvalid,
  output logic        s_axi_wready,
  input  logic [31:0] s_axi_wdata,
  input  logic [3:0]  s_axi_wstrb,
  
  // AXI4-Lite Slave Interface - Write Response Channel
  output logic        s_axi_bvalid,
  input  logic        s_axi_bready,
  output logic [1:0]  s_axi_bresp,
  
  // AXI4-Lite Slave Interface - Read Address Channel
  input  logic        s_axi_arvalid,
  output logic        s_axi_arready,
  input  logic [31:0] s_axi_araddr,
  input  logic [2:0]  s_axi_arprot,
  
  // AXI4-Lite Slave Interface - Read Data Channel
  output logic        s_axi_rvalid,
  input  logic        s_axi_rready,
  output logic [31:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp
);

  // 内部状态和信号定义
  logic [1:0] current_state, next_state;
  logic locked, locked_comb;
  logic in_reg;
  logic rst;
  
  // 寄存器地址定义
  localparam REG_CONTROL = 4'h0;    // 控制寄存器 [0] = in
  localparam REG_STATUS  = 4'h4;    // 状态寄存器 [0] = locked
  
  // 状态定义
  localparam WAIT = 2'b00,
             GOT1 = 2'b01,
             GOT10= 2'b10,
             UNLK = 2'b11;

  // AXI4-Lite 接口内部信号
  logic [3:0]  axi_awaddr;
  logic        axi_awready_ff;
  logic        axi_wready_ff;
  logic [1:0]  axi_bresp_ff;
  logic        axi_bvalid_ff;
  logic [3:0]  axi_araddr;
  logic        axi_arready_ff;
  logic [31:0] axi_rdata_ff;
  logic [1:0]  axi_rresp_ff;
  logic        axi_rvalid_ff;
  
  // 写地址通道握手处理
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      axi_awready_ff <= 1'b0;
      axi_awaddr <= 4'h0;
    end else begin
      if (~axi_awready_ff && s_axi_awvalid && ~axi_bvalid_ff) begin
        axi_awready_ff <= 1'b1;
        axi_awaddr <= s_axi_awaddr[5:2];
      end else begin
        axi_awready_ff <= 1'b0;
      end
    end
  end
  
  // 写数据通道握手处理
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      axi_wready_ff <= 1'b0;
    end else begin
      if (~axi_wready_ff && s_axi_wvalid && s_axi_awvalid && ~axi_bvalid_ff) begin
        axi_wready_ff <= 1'b1;
      end else begin
        axi_wready_ff <= 1'b0;
      end
    end
  end
  
  // 写操作处理
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      in_reg <= 1'b0;
      rst <= 1'b1;
    end else begin
      rst <= 1'b0; // 默认复位信号为低
      
      if (axi_wready_ff && s_axi_wvalid && axi_awready_ff && s_axi_awvalid) begin
        case (axi_awaddr)
          REG_CONTROL: begin
            if (s_axi_wstrb[0]) begin
              in_reg <= s_axi_wdata[0];
              rst <= s_axi_wdata[1]; // 复位信号可通过写入控制
            end
          end
          default: begin
            // 保持不变
          end
        endcase
      end
    end
  end
  
  // 写响应通道处理
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      axi_bvalid_ff <= 1'b0;
      axi_bresp_ff <= 2'b0;
    end else begin
      if (axi_wready_ff && s_axi_wvalid && axi_awready_ff && s_axi_awvalid && ~axi_bvalid_ff) begin
        axi_bvalid_ff <= 1'b1;
        axi_bresp_ff <= 2'b00; // OKAY响应
      end else if (s_axi_bready && axi_bvalid_ff) begin
        axi_bvalid_ff <= 1'b0;
      end
    end
  end
  
  // 读地址通道握手处理
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      axi_arready_ff <= 1'b0;
      axi_araddr <= 4'h0;
    end else begin
      if (~axi_arready_ff && s_axi_arvalid && ~axi_rvalid_ff) begin
        axi_arready_ff <= 1'b1;
        axi_araddr <= s_axi_araddr[5:2];
      end else begin
        axi_arready_ff <= 1'b0;
      end
    end
  end
  
  // 读数据通道处理
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      axi_rvalid_ff <= 1'b0;
      axi_rresp_ff <= 2'b0;
    end else begin
      if (axi_arready_ff && s_axi_arvalid && ~axi_rvalid_ff) begin
        axi_rvalid_ff <= 1'b1;
        axi_rresp_ff <= 2'b00; // OKAY响应
      end else if (axi_rvalid_ff && s_axi_rready) begin
        axi_rvalid_ff <= 1'b0;
      end
    end
  end
  
  // 读数据返回处理
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      axi_rdata_ff <= 32'h0;
    end else begin
      if (axi_arready_ff && s_axi_arvalid && ~axi_rvalid_ff) begin
        case (axi_araddr)
          REG_CONTROL: begin
            axi_rdata_ff <= {30'b0, rst, in_reg}; // 控制寄存器读取
          end
          REG_STATUS: begin
            axi_rdata_ff <= {31'b0, locked}; // 状态寄存器读取
          end
          default: begin
            axi_rdata_ff <= 32'h0; // 默认返回0
          end
        endcase
      end
    end
  end

  // 时序逻辑 - 状态寄存器
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn || rst) begin
      current_state <= WAIT;
    end else begin
      current_state <= next_state;
    end
  end

  // 时序逻辑 - 输出寄存器
  always_ff @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn || rst) begin
      locked <= 1'b1;
    end else begin
      locked <= locked_comb;
    end
  end

  // 组合逻辑 - 下一状态计算模块
  moore_next_state_logic next_state_logic_inst (
    .current_state(current_state),
    .in(in_reg),
    .next_state(next_state)
  );

  // 组合逻辑 - 输出计算模块
  moore_output_logic output_logic_inst (
    .current_state(current_state),
    .locked(locked_comb)
  );
  
  // AXI信号输出连接
  assign s_axi_awready = axi_awready_ff;
  assign s_axi_wready = axi_wready_ff;
  assign s_axi_bresp = axi_bresp_ff;
  assign s_axi_bvalid = axi_bvalid_ff;
  assign s_axi_arready = axi_arready_ff;
  assign s_axi_rdata = axi_rdata_ff;
  assign s_axi_rresp = axi_rresp_ff;
  assign s_axi_rvalid = axi_rvalid_ff;

endmodule

// 组合逻辑模块：计算下一状态
module moore_next_state_logic (
  input [1:0] current_state,
  input in,
  output reg [1:0] next_state
);
  // 状态参数定义
  localparam WAIT = 2'b00,
             GOT1 = 2'b01,
             GOT10= 2'b10,
             UNLK = 2'b11;

  // 纯组合逻辑实现状态转换
  always @(*) begin
    // 默认保持当前状态
    next_state = current_state;
    
    case (current_state)
      WAIT:  if (in) next_state = GOT1;
      GOT1:  if (!in) next_state = GOT10;
             else next_state = GOT1;
      GOT10: if (in) next_state = UNLK;
             else next_state = WAIT;
      UNLK:  next_state = UNLK;
      default: next_state = WAIT;
    endcase
  end
endmodule

// 组合逻辑模块：计算输出
module moore_output_logic (
  input [1:0] current_state,
  output reg locked
);
  // 状态参数定义
  localparam WAIT = 2'b00,
             GOT1 = 2'b01,
             GOT10= 2'b10,
             UNLK = 2'b11;

  // 纯组合逻辑实现输出计算
  always @(*) begin
    // 默认锁定
    locked = 1'b1;
    
    case (current_state)
      UNLK: locked = 1'b0;
      default: locked = 1'b1;
    endcase
  end
endmodule