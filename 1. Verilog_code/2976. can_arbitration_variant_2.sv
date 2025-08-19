//SystemVerilog
//IEEE 1364-2005 Verilog标准
module can_arbitration_axi (
  // 全局信号
  input wire aclk,
  input wire aresetn,
  
  // AXI4-Lite 写地址通道
  input wire [31:0] s_axil_awaddr,
  input wire [2:0] s_axil_awprot,
  input wire s_axil_awvalid,
  output reg s_axil_awready,
  
  // AXI4-Lite 写数据通道
  input wire [31:0] s_axil_wdata,
  input wire [3:0] s_axil_wstrb,
  input wire s_axil_wvalid,
  output reg s_axil_wready,
  
  // AXI4-Lite 写响应通道
  output reg [1:0] s_axil_bresp,
  output reg s_axil_bvalid,
  input wire s_axil_bready,
  
  // AXI4-Lite 读地址通道
  input wire [31:0] s_axil_araddr,
  input wire [2:0] s_axil_arprot,
  input wire s_axil_arvalid,
  output reg s_axil_arready,
  
  // AXI4-Lite 读数据通道
  output reg [31:0] s_axil_rdata,
  output reg [1:0] s_axil_rresp,
  output reg s_axil_rvalid,
  input wire s_axil_rready,
  
  // CAN接口信号
  input wire can_rx,
  output reg can_tx
);

  // 内部寄存器
  reg [10:0] shift_id_stage1;
  reg [10:0] shift_id_stage2;
  reg [10:0] shift_id_stage3;
  reg [10:0] shift_id_stage4;
  reg [3:0] bit_count_stage1;
  reg [3:0] bit_count_stage2;
  reg [3:0] bit_count_stage3;
  reg in_arbitration_stage1;
  reg in_arbitration_stage2;
  reg in_arbitration_stage3;
  reg arbitration_lost_stage1;
  reg arbitration_lost_stage2;
  reg arbitration_lost_stage3;
  reg [10:0] tx_id_stage1;
  reg [10:0] tx_id_stage2;
  reg tx_start_stage1;
  reg tx_start_stage2;
  reg tx_start_stage3;
  
  // CAN状态流水线寄存器
  reg can_rx_stage1;
  reg can_rx_stage2;
  reg can_tx_stage1;
  reg can_tx_stage2;
  
  // 寄存器地址定义
  localparam ADDR_CTRL     = 4'h0;    // 控制寄存器 (tx_start at bit 0)
  localparam ADDR_TX_ID    = 4'h4;    // 发送ID寄存器
  localparam ADDR_STATUS   = 4'h8;    // 状态寄存器 (arbitration_lost at bit 0)
  
  // AXI4-Lite 写事务处理流水线寄存器
  reg [2:0] write_state_stage1;       // 增加状态位以支持更多流水线级
  reg [2:0] write_state_stage2;
  localparam WRITE_IDLE = 3'b000;
  localparam WRITE_ADDR_CAPTURE = 3'b001;
  localparam WRITE_DATA_WAIT = 3'b010;
  localparam WRITE_DATA_PROCESS = 3'b011;
  localparam WRITE_RESP = 3'b100;
  reg [31:0] awaddr_stage1;
  reg [31:0] awaddr_stage2;
  reg [31:0] wdata_stage1;
  reg [3:0] wstrb_stage1;
  
  // AXI4-Lite 读事务处理流水线寄存器
  reg [2:0] read_state_stage1;
  reg [2:0] read_state_stage2;
  localparam READ_IDLE = 3'b000;
  localparam READ_ADDR_CAPTURE = 3'b001;
  localparam READ_DATA_PREPARE = 3'b010;
  localparam READ_DATA_VALID = 3'b011;
  reg [31:0] araddr_stage1;
  reg [31:0] araddr_stage2;
  reg [31:0] rdata_stage1;
  
  // 写地址通道处理 - 第一级流水线
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      write_state_stage1 <= WRITE_IDLE;
      s_axil_awready <= 1'b0;
      awaddr_stage1 <= 32'h0;
    end else begin
      case (write_state_stage1)
        WRITE_IDLE: begin
          if (s_axil_awvalid && !s_axil_awready) begin
            s_axil_awready <= 1'b1;
            awaddr_stage1 <= s_axil_awaddr;
            write_state_stage1 <= WRITE_ADDR_CAPTURE;
          end
        end
        
        WRITE_ADDR_CAPTURE: begin
          s_axil_awready <= 1'b0;
          write_state_stage1 <= WRITE_DATA_WAIT;
        end
        
        WRITE_DATA_WAIT: begin
          if (write_state_stage2 == WRITE_IDLE) begin
            write_state_stage1 <= WRITE_IDLE;
          end
        end
        
        default: begin
          write_state_stage1 <= WRITE_IDLE;
        end
      endcase
    end
  end
  
  // 写数据通道处理 - 第二级流水线
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      write_state_stage2 <= WRITE_IDLE;
      s_axil_wready <= 1'b0;
      s_axil_bvalid <= 1'b0;
      s_axil_bresp <= 2'b00;
      awaddr_stage2 <= 32'h0;
      wdata_stage1 <= 32'h0;
      wstrb_stage1 <= 4'h0;
      tx_id_stage1 <= 11'h0;
      tx_start_stage1 <= 1'b0;
    end else begin
      // 将地址从第一级传递到第二级
      if (write_state_stage1 == WRITE_ADDR_CAPTURE) begin
        awaddr_stage2 <= awaddr_stage1;
      end
      
      // 自动清除tx_start信号
      if (tx_start_stage1) begin
        tx_start_stage1 <= 1'b0;
      end
      
      case (write_state_stage2)
        WRITE_IDLE: begin
          if (write_state_stage1 == WRITE_DATA_WAIT) begin
            if (s_axil_wvalid && !s_axil_wready) begin
              s_axil_wready <= 1'b1;
              wdata_stage1 <= s_axil_wdata;
              wstrb_stage1 <= s_axil_wstrb;
              write_state_stage2 <= WRITE_DATA_PROCESS;
            end
          end
        end
        
        WRITE_DATA_PROCESS: begin
          s_axil_wready <= 1'b0;
          
          // 寄存器写操作
          case (awaddr_stage2[3:0])
            ADDR_CTRL: begin
              if (wstrb_stage1[0]) begin
                tx_start_stage1 <= wdata_stage1[0];
              end
            end
            
            ADDR_TX_ID: begin
              if (wstrb_stage1[0]) begin
                tx_id_stage1[7:0] <= wdata_stage1[7:0];
              end
              if (wstrb_stage1[1]) begin
                tx_id_stage1[10:8] <= wdata_stage1[10:8];
              end
            end
            
            default: begin
              // 无操作
            end
          endcase
          
          write_state_stage2 <= WRITE_RESP;
        end
        
        WRITE_RESP: begin
          s_axil_bvalid <= 1'b1;
          s_axil_bresp <= 2'b00;  // OKAY响应
          
          if (s_axil_bready && s_axil_bvalid) begin
            s_axil_bvalid <= 1'b0;
            write_state_stage2 <= WRITE_IDLE;
          end
        end
        
        default: begin
          write_state_stage2 <= WRITE_IDLE;
        end
      endcase
    end
  end
  
  // 读地址通道处理 - 第一级流水线
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      read_state_stage1 <= READ_IDLE;
      s_axil_arready <= 1'b0;
      araddr_stage1 <= 32'h0;
    end else begin
      case (read_state_stage1)
        READ_IDLE: begin
          if (s_axil_arvalid && !s_axil_arready) begin
            s_axil_arready <= 1'b1;
            araddr_stage1 <= s_axil_araddr;
            read_state_stage1 <= READ_ADDR_CAPTURE;
          end
        end
        
        READ_ADDR_CAPTURE: begin
          s_axil_arready <= 1'b0;
          read_state_stage1 <= READ_DATA_PREPARE;
        end
        
        READ_DATA_PREPARE: begin
          if (read_state_stage2 == READ_IDLE) begin
            read_state_stage1 <= READ_IDLE;
          end
        end
        
        default: begin
          read_state_stage1 <= READ_IDLE;
        end
      endcase
    end
  end
  
  // 读数据通道处理 - 第二级流水线
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      read_state_stage2 <= READ_IDLE;
      s_axil_rvalid <= 1'b0;
      s_axil_rresp <= 2'b00;
      s_axil_rdata <= 32'h0;
      araddr_stage2 <= 32'h0;
      rdata_stage1 <= 32'h0;
    end else begin
      // 将地址从第一级传递到第二级
      if (read_state_stage1 == READ_ADDR_CAPTURE) begin
        araddr_stage2 <= araddr_stage1;
      end
      
      case (read_state_stage2)
        READ_IDLE: begin
          if (read_state_stage1 == READ_DATA_PREPARE) begin
            read_state_stage2 <= READ_DATA_VALID;
            
            // 寄存器读操作 - 准备数据
            case (araddr_stage2[3:0])
              ADDR_CTRL: begin
                rdata_stage1 <= {31'h0, tx_start_stage2};
              end
              
              ADDR_TX_ID: begin
                rdata_stage1 <= {21'h0, tx_id_stage2};
              end
              
              ADDR_STATUS: begin
                rdata_stage1 <= {28'h0, bit_count_stage3, arbitration_lost_stage3};
              end
              
              default: begin
                rdata_stage1 <= 32'h0;
              end
            endcase
          end
        end
        
        READ_DATA_VALID: begin
          s_axil_rvalid <= 1'b1;
          s_axil_rresp <= 2'b00;  // OKAY响应
          s_axil_rdata <= rdata_stage1;
          
          if (s_axil_rready && s_axil_rvalid) begin
            s_axil_rvalid <= 1'b0;
            read_state_stage2 <= READ_IDLE;
          end
        end
        
        default: begin
          read_state_stage2 <= READ_IDLE;
        end
      endcase
    end
  end
  
  // TX ID和TX Start信号的流水线传递
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      tx_id_stage2 <= 11'h0;
      tx_start_stage2 <= 1'b0;
      tx_start_stage3 <= 1'b0;
    end else begin
      tx_id_stage2 <= tx_id_stage1;
      tx_start_stage2 <= tx_start_stage1;
      tx_start_stage3 <= tx_start_stage2;
    end
  end
  
  // CAN输入输出流水线
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      can_rx_stage1 <= 1'b1;
      can_rx_stage2 <= 1'b1;
      can_tx_stage1 <= 1'b1;
      can_tx_stage2 <= 1'b1;
      can_tx <= 1'b1;
    end else begin
      can_rx_stage1 <= can_rx;
      can_rx_stage2 <= can_rx_stage1;
      can_tx_stage1 <= can_tx_stage2;
      can_tx <= can_tx_stage1;
    end
  end
  
  // CAN仲裁逻辑 - 第一级流水线：初始化和开始仲裁
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      shift_id_stage1 <= 11'h0;
      in_arbitration_stage1 <= 1'b0;
      bit_count_stage1 <= 4'h0;
    end else if (tx_start_stage3) begin
      shift_id_stage1 <= tx_id_stage2;
      in_arbitration_stage1 <= 1'b1;
      bit_count_stage1 <= 4'h0;
    end else if (in_arbitration_stage1) begin
      bit_count_stage1 <= bit_count_stage1 + 4'h1;
      shift_id_stage1 <= {shift_id_stage1[9:0], 1'b0};
    end
  end
  
  // CAN仲裁逻辑 - 第二级流水线：位计数和ID移位
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      shift_id_stage2 <= 11'h0;
      shift_id_stage3 <= 11'h0;
      bit_count_stage2 <= 4'h0;
      in_arbitration_stage2 <= 1'b0;
    end else begin
      shift_id_stage2 <= shift_id_stage1;
      shift_id_stage3 <= shift_id_stage2;
      bit_count_stage2 <= bit_count_stage1;
      in_arbitration_stage2 <= in_arbitration_stage1;
    end
  end
  
  // CAN仲裁逻辑 - 第三级流水线：仲裁决策
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      shift_id_stage4 <= 11'h0;
      bit_count_stage3 <= 4'h0;
      in_arbitration_stage3 <= 1'b0;
      arbitration_lost_stage1 <= 1'b0;
      can_tx_stage2 <= 1'b1;
    end else begin
      shift_id_stage4 <= shift_id_stage3;
      bit_count_stage3 <= bit_count_stage2;
      in_arbitration_stage3 <= in_arbitration_stage2;
      
      if (in_arbitration_stage2 && bit_count_stage2 < 4'hB) begin
        can_tx_stage2 <= shift_id_stage3[10];
        arbitration_lost_stage1 <= (can_rx_stage2 == 1'b0 && shift_id_stage4[10] == 1'b1);
      end
    end
  end
  
  // 仲裁结果流水线延迟
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      arbitration_lost_stage2 <= 1'b0;
      arbitration_lost_stage3 <= 1'b0;
    end else begin
      arbitration_lost_stage2 <= arbitration_lost_stage1;
      arbitration_lost_stage3 <= arbitration_lost_stage2;
    end
  end

endmodule