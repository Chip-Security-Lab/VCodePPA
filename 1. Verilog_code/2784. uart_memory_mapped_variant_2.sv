//SystemVerilog
module uart_memory_mapped #(parameter ADDR_WIDTH = 4) (
  input wire clk, reset_n,
  // Bus interface
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [7:0] wdata,
  input wire write_en, read_en,
  output reg [7:0] rdata,
  // UART signals
  input wire rx_in,
  output wire tx_out
);
  // Register map
  localparam REG_TX_DATA = 4'h0;    // Write: TX data
  localparam REG_RX_DATA = 4'h1;    // Read: RX data
  localparam REG_STATUS = 4'h2;     // Read: Status register
  localparam REG_CONTROL = 4'h3;    // R/W: Control register
  localparam REG_BAUD_DIV = 4'h4;   // R/W: Baud rate divider
  localparam REG_MULT_A = 4'h5;     // R/W: Multiplier input A
  localparam REG_MULT_B = 4'h6;     // R/W: Multiplier input B
  localparam REG_MULT_RES_L = 4'h7; // Read: Multiplier result low byte
  localparam REG_MULT_RES_H = 4'h8; // Read: Multiplier result high byte
  
  // Internal registers
  reg [7:0] tx_data_reg;
  reg [7:0] rx_data_reg;
  reg [7:0] status_reg;  // [7:rx_ready, 6:tx_busy, 5:rx_overrun, 4:frame_err, 3-0:reserved]
  reg [7:0] control_reg; // [7:rx_int_en, 6:tx_int_en, 5:rx_en, 4:tx_en, 3-0:reserved]
  reg [7:0] baud_div_reg;
  reg [7:0] mult_a_reg;  // Multiplier input A
  reg [7:0] mult_b_reg;  // Multiplier input B
  wire [15:0] mult_result; // Multiplier result
  
  // UART control signals
  reg tx_start;
  wire tx_busy, rx_ready;
  wire [7:0] rx_data;
  wire frame_error;
  wire tx_done;
  
  // Baugh-Wooley multiplier with parallel prefix adder implementation
  reg [14:0] pp [7:0];  // Partial products
  
  // Parallel prefix adder signals for 16-bit addition
  wire [15:0] prefix_sum;
  
  // Generate and propagate signals for parallel prefix adder
  wire [15:0] g, p; // Generate and propagate signals
  wire [15:0] g_l1, p_l1; // Level 1
  wire [15:0] g_l2, p_l2; // Level 2
  wire [15:0] g_l3, p_l3; // Level 3
  wire [15:0] g_l4, p_l4; // Level 4
  wire [15:0] carry; // Carry signals
  
  // Generate partial products using Baugh-Wooley algorithm
  always @(*) begin
    integer i, j;
    // Initialize partial products
    for (i = 0; i < 8; i = i + 1) begin
      pp[i] = 15'b0;
    end
    
    // Generate partial products for bits 0 to 6
    for (i = 0; i < 7; i = i + 1) begin
      for (j = 0; j < 7; j = j + 1) begin
        pp[i][j+i] = mult_a_reg[i] & mult_b_reg[j];
      end
      // Handle sign bit of multiplier
      pp[i][7+i] = mult_a_reg[i] & (~mult_b_reg[7]);
    end
    
    // Generate partial product for sign bit of multiplicand
    for (j = 0; j < 7; j = j + 1) begin
      pp[7][j+7] = (~mult_a_reg[7]) & mult_b_reg[j];
    end
    
    // Special handling for MSB of both operands
    pp[7][14] = mult_a_reg[7] & mult_b_reg[7];
  end
  
  // Parallel Prefix Adder Implementation
  // Step 1: Initialize 16-bit values for addition
  wire [15:0] operand_a, operand_b;
  assign operand_a = {1'b0, pp[0]} + {1'b0, pp[1]} + {1'b0, pp[2]} + {1'b0, pp[3]};
  assign operand_b = {1'b0, pp[4]} + {1'b0, pp[5]} + {1'b0, pp[6]} + {1'b0, pp[7]} + 16'h0001; // Including correction term
  
  // Step 2: Generate initial generate and propagate signals
  assign g = operand_a & operand_b;
  assign p = operand_a | operand_b;
  
  // Step 3: Parallel prefix computation - Kogge-Stone algorithm
  // Level 1: i:j = i:i-1 + i-1:j where j=i-2^0
  assign g_l1[0] = g[0];
  assign p_l1[0] = p[0];
  
  genvar k;
  generate
    for (k = 1; k < 16; k = k + 1) begin : level1_prefix
      assign g_l1[k] = g[k] | (p[k] & g[k-1]);
      assign p_l1[k] = p[k] & p[k-1];
    end
  endgenerate
  
  // Level 2: i:j = i:i-1 + i-1:j where j=i-2^1
  assign g_l2[0] = g_l1[0];
  assign p_l2[0] = p_l1[0];
  assign g_l2[1] = g_l1[1];
  assign p_l2[1] = p_l1[1];
  
  generate
    for (k = 2; k < 16; k = k + 1) begin : level2_prefix
      assign g_l2[k] = g_l1[k] | (p_l1[k] & g_l1[k-2]);
      assign p_l2[k] = p_l1[k] & p_l1[k-2];
    end
  endgenerate
  
  // Level 3: i:j = i:i-1 + i-1:j where j=i-2^2
  assign g_l3[0] = g_l2[0];
  assign p_l3[0] = p_l2[0];
  assign g_l3[1] = g_l2[1];
  assign p_l3[1] = p_l2[1];
  assign g_l3[2] = g_l2[2];
  assign p_l3[2] = p_l2[2];
  assign g_l3[3] = g_l2[3];
  assign p_l3[3] = p_l2[3];
  
  generate
    for (k = 4; k < 16; k = k + 1) begin : level3_prefix
      assign g_l3[k] = g_l2[k] | (p_l2[k] & g_l2[k-4]);
      assign p_l3[k] = p_l2[k] & p_l2[k-4];
    end
  endgenerate
  
  // Level 4: i:j = i:i-1 + i-1:j where j=i-2^3
  assign g_l4[0] = g_l3[0];
  assign p_l4[0] = p_l3[0];
  assign g_l4[1] = g_l3[1];
  assign p_l4[1] = p_l3[1];
  assign g_l4[2] = g_l3[2];
  assign p_l4[2] = p_l3[2];
  assign g_l4[3] = g_l3[3];
  assign p_l4[3] = p_l3[3];
  assign g_l4[4] = g_l3[4];
  assign p_l4[4] = p_l3[4];
  assign g_l4[5] = g_l3[5];
  assign p_l4[5] = p_l3[5];
  assign g_l4[6] = g_l3[6];
  assign p_l4[6] = p_l3[6];
  assign g_l4[7] = g_l3[7];
  assign p_l4[7] = p_l3[7];
  
  generate
    for (k = 8; k < 16; k = k + 1) begin : level4_prefix
      assign g_l4[k] = g_l3[k] | (p_l3[k] & g_l3[k-8]);
      assign p_l4[k] = p_l3[k] & p_l3[k-8];
    end
  endgenerate
  
  // Step 4: Compute carry signals
  assign carry[0] = 1'b0; // No carry-in for LSB
  assign carry[1] = g_l4[0];
  assign carry[2] = g_l4[1];
  assign carry[3] = g_l4[2];
  assign carry[4] = g_l4[3];
  assign carry[5] = g_l4[4];
  assign carry[6] = g_l4[5];
  assign carry[7] = g_l4[6];
  assign carry[8] = g_l4[7];
  assign carry[9] = g_l4[8];
  assign carry[10] = g_l4[9];
  assign carry[11] = g_l4[10];
  assign carry[12] = g_l4[11];
  assign carry[13] = g_l4[12];
  assign carry[14] = g_l4[13];
  assign carry[15] = g_l4[14];
  
  // Step 5: Calculate sum
  assign prefix_sum[0] = operand_a[0] ^ operand_b[0] ^ 1'b0;
  generate
    for (k = 1; k < 16; k = k + 1) begin : sum_calculation
      assign prefix_sum[k] = operand_a[k] ^ operand_b[k] ^ carry[k];
    end
  endgenerate
  
  // Connect the multiplier output
  assign mult_result = prefix_sum;
  
  // Bus interface logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_data_reg <= 0;
      control_reg <= 8'h30; // Enable TX and RX by default
      baud_div_reg <= 8'd16; // Default baud divider
      tx_start <= 0;
      status_reg <= 0;
      rx_data_reg <= 0;
      mult_a_reg <= 0;
      mult_b_reg <= 0;
    end else begin
      tx_start <= 0; // Auto-clear tx_start
      
      // Write operations
      if (write_en) begin
        case (addr)
          REG_TX_DATA: begin
            tx_data_reg <= wdata;
            if (control_reg[4]) tx_start <= 1; // Auto-start TX if enabled
          end
          REG_CONTROL: control_reg <= wdata;
          REG_BAUD_DIV: baud_div_reg <= wdata;
          REG_MULT_A: mult_a_reg <= wdata;
          REG_MULT_B: mult_b_reg <= wdata;
          default: ; // No operation for other addresses
        endcase
      end
      
      // Clear status bits when read
      if (read_en && addr == REG_STATUS) begin
        status_reg[5] <= 0; // Clear overrun flag on read
      end
      
      // Update status register
      status_reg[7] <= rx_ready;
      status_reg[6] <= tx_busy;
      status_reg[4] <= frame_error;
      
      // Handle RX data and overrun detection
      if (rx_ready) begin
        if (status_reg[7]) status_reg[5] <= 1; // Set overrun flag
        rx_data_reg <= rx_data;
      end
    end
  end
  
  // Read operations
  always @(*) begin
    case (addr)
      REG_RX_DATA: rdata = rx_data_reg;
      REG_STATUS:  rdata = status_reg;
      REG_CONTROL: rdata = control_reg;
      REG_BAUD_DIV: rdata = baud_div_reg;
      REG_MULT_A: rdata = mult_a_reg;
      REG_MULT_B: rdata = mult_b_reg;
      REG_MULT_RES_L: rdata = mult_result[7:0];
      REG_MULT_RES_H: rdata = mult_result[15:8];
      default:     rdata = 8'h00;
    endcase
  end
  
  // 为引用的模块创建简单的桩实现
  
  // 简单的TX桩
  assign tx_out = 1'b1; // 空闲状态为高电平
  assign tx_busy = tx_start; // 启动时忙
  assign tx_done = !tx_busy && tx_start;
  
  // 简单的RX桩
  assign rx_ready = rx_in; // 输入高电平时就绪
  assign rx_data = 8'hAA; // 测试数据
  assign frame_error = 1'b0; // 无错误
  
endmodule