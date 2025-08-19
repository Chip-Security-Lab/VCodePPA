//SystemVerilog
//IEEE 1364-2005 Verilog standard
module vectored_intr_ctrl #(
  parameter SOURCES = 16,
  parameter VEC_WIDTH = 8
)(
  input clk, rstn,
  input [SOURCES-1:0] intr_src,
  input [SOURCES*VEC_WIDTH-1:0] vector_table,
  output reg [VEC_WIDTH-1:0] intr_vector,
  output reg valid
);
  
  reg [SOURCES-1:0] priority_mask;
  reg [$clog2(SOURCES)-1:0] selected_intr;
  reg intr_detected;
  
  // Buffered signals for high fan-out mitigation
  reg intr_detected_buf1, intr_detected_buf2, intr_detected_buf3;
  reg [3:0] i_buf [0:3]; // Divide loop counter into 4 buffered regions
  
  integer i;
  
  // 优先级编码器实现
  always @(*) begin
    priority_mask = {SOURCES{1'b0}};
    intr_detected = 1'b0;
    selected_intr = {$clog2(SOURCES){1'b0}};
    
    // 使用优先级编码，从高到低扫描中断源
    for (i = SOURCES-1; i >= 0; i = i - 1) begin
      // Assign buffered loop counters for different sections
      i_buf[0] = (i >= 12) ? i[3:0] : 4'b0;
      i_buf[1] = ((i >= 8) && (i < 12)) ? i[3:0] : 4'b0;
      i_buf[2] = ((i >= 4) && (i < 8)) ? i[3:0] : 4'b0;
      i_buf[3] = (i < 4) ? i[3:0] : 4'b0;
      
      if (intr_src[i] && !intr_detected) begin
        priority_mask[i] = 1'b1;
        selected_intr = i[$clog2(SOURCES)-1:0];
        intr_detected = 1'b1;
      end
    end
  end
  
  // Buffer registers for intr_detected signal to reduce fan-out
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      intr_detected_buf1 <= 1'b0;
      intr_detected_buf2 <= 1'b0;
      intr_detected_buf3 <= 1'b0;
    end else begin
      intr_detected_buf1 <= intr_detected;
      intr_detected_buf2 <= intr_detected;
      intr_detected_buf3 <= intr_detected;
    end
  end
  
  // Vector selection logic - uses buffered intr_detected signal
  reg [$clog2(SOURCES)-1:0] selected_intr_reg;
  
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      selected_intr_reg <= {$clog2(SOURCES){1'b0}};
    end else if (intr_detected_buf1) begin
      selected_intr_reg <= selected_intr;
    end
  end
  
  // Main state logic - synchronized sequential block
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      intr_vector <= {VEC_WIDTH{1'b0}};
      valid <= 1'b0;
    end else begin
      valid <= intr_detected_buf2; // Use buffered version
      if (intr_detected_buf3)      // Use buffered version
        intr_vector <= vector_table[selected_intr_reg*VEC_WIDTH+:VEC_WIDTH];
      else
        intr_vector <= intr_vector; // 保持当前值，避免不必要的切换
    end
  end
  
endmodule