//SystemVerilog
module can_crc_generator(
  input  wire        clk,           // 时钟
  input  wire        rst_n,         // 低电平有效复位
  input  wire        bit_in,        // 输入数据位
  input  wire        bit_valid,     // 输入数据有效标志
  output wire        bit_ready,     // 模块准备好接收数据
  input  wire        crc_start,     // CRC计算开始信号
  output wire [14:0] crc_out,       // CRC计算结果
  output wire        crc_out_valid, // CRC结果有效标志
  input  wire        crc_out_ready, // 接收方准备好接收CRC
  output wire        crc_error      // CRC错误指示
);
  localparam [14:0] CRC_POLY = 15'h4599; // CAN CRC polynomial
  
  // Stage 1: Input processing and CRC computation
  reg [14:0] crc_reg_stage1;
  reg processing_stage1;
  reg valid_stage1;
  reg error_stage1;
  
  // Stage 2: Further CRC processing
  reg [14:0] crc_reg_stage2;
  reg processing_stage2;
  reg valid_stage2;
  reg error_stage2;
  reg stage2_ready_r;
  
  // Stage 3: Output preparation
  reg [14:0] crc_reg_stage3;
  reg processing_stage3;
  reg valid_stage3;
  reg error_stage3;
  reg stage3_ready_r;
  
  // Improved handshake signals with Valid-Ready protocol
  wire bit_transfer    = bit_valid && bit_ready;
  wire stage1_ready    = !valid_stage1 || (valid_stage1 && stage2_ready_r);
  wire stage2_ready    = !valid_stage2 || (valid_stage2 && stage3_ready_r);
  wire stage3_ready    = !valid_stage3 || (valid_stage3 && crc_out_ready);
  wire out_transfer    = crc_out_valid && crc_out_ready;
  
  // Generate ready signals for pipeline stages
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage2_ready_r <= 1'b1;
      stage3_ready_r <= 1'b1;
    end else begin
      stage2_ready_r <= stage2_ready;
      stage3_ready_r <= stage3_ready;
    end
  end
  
  // Stage 1: Input processing and initial CRC computation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg_stage1  <= 15'h0;
      processing_stage1 <= 1'b0;
      valid_stage1    <= 1'b0;
      error_stage1    <= 1'b0;
    end else if (crc_start) begin
      crc_reg_stage1  <= 15'h0;
      processing_stage1 <= 1'b1;
      valid_stage1    <= 1'b0;
      error_stage1    <= 1'b0;
    end else if (bit_transfer && processing_stage1 && stage1_ready) begin
      // CRC computation logic
      if (bit_in ^ crc_reg_stage1[14]) 
        crc_reg_stage1 <= {crc_reg_stage1[13:0], 1'b0} ^ CRC_POLY;
      else
        crc_reg_stage1 <= {crc_reg_stage1[13:0], 1'b0};
        
      valid_stage1    <= 1'b1;
      error_stage1    <= (crc_reg_stage1 == 15'h0) ? 1'b0 : 1'b1;
    end else if (valid_stage1 && stage2_ready_r) begin
      valid_stage1    <= 1'b0;
    end
  end
  
  // Stage 2: Further CRC processing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg_stage2  <= 15'h0;
      processing_stage2 <= 1'b0;
      valid_stage2    <= 1'b0;
      error_stage2    <= 1'b0;
    end else if (crc_start) begin
      crc_reg_stage2  <= 15'h0;
      processing_stage2 <= 1'b0;
      valid_stage2    <= 1'b0;
      error_stage2    <= 1'b0;
    end else if (valid_stage1 && stage2_ready) begin
      crc_reg_stage2  <= crc_reg_stage1;
      processing_stage2 <= processing_stage1;
      valid_stage2    <= 1'b1;
      error_stage2    <= error_stage1;
    end else if (valid_stage2 && stage3_ready_r) begin
      valid_stage2    <= 1'b0;
    end
  end
  
  // Stage 3: Output preparation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc_reg_stage3  <= 15'h0;
      processing_stage3 <= 1'b0;
      valid_stage3    <= 1'b0;
      error_stage3    <= 1'b0;
    end else if (crc_start) begin
      crc_reg_stage3  <= 15'h0;
      processing_stage3 <= 1'b0;
      valid_stage3    <= 1'b0;
      error_stage3    <= 1'b0;
    end else if (valid_stage2 && stage3_ready) begin
      crc_reg_stage3  <= crc_reg_stage2;
      processing_stage3 <= processing_stage2;
      valid_stage3    <= 1'b1;
      error_stage3    <= error_stage2;
    end else if (out_transfer) begin
      valid_stage3    <= 1'b0;
      processing_stage3 <= 1'b0;
    end
  end
  
  // Output assignments with Valid-Ready protocol
  assign crc_out       = crc_reg_stage3;
  assign crc_out_valid = valid_stage3;
  assign crc_error     = error_stage3;
  assign bit_ready     = processing_stage1 && stage1_ready;
  
endmodule