//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 compliant
module prio_enc_lut #(parameter DEPTH=8)(
  input [DEPTH-1:0] in,
  output [$clog2(DEPTH)-1:0] out
);
  
  // Internal signals
  reg [$clog2(DEPTH)-1:0] out_depth8;
  reg [$clog2(DEPTH)-1:0] out_generic;
  wire use_depth8 = (DEPTH == 8);
  
  // DEPTH=8 优化编码器实现
  generate
    if (DEPTH == 8) begin : depth_8_encoder
      // 高位优先检测块 (bits 7-4)
      reg high_bits_valid;
      reg [1:0] high_bits_value;
      
      always @(*) begin
        high_bits_valid = 1'b0;
        high_bits_value = 2'b00;
        
        if (in[7]) begin
          high_bits_valid = 1'b1;
          high_bits_value = 2'b11;
        end
        else if (in[6]) begin
          high_bits_valid = 1'b1;
          high_bits_value = 2'b10;
        end
        else if (in[5]) begin
          high_bits_valid = 1'b1;
          high_bits_value = 2'b01;
        end
        else if (in[4]) begin
          high_bits_valid = 1'b1;
          high_bits_value = 2'b00;
        end
      end
      
      // 低位优先检测块 (bits 3-0)
      reg [1:0] low_bits_value;
      
      always @(*) begin
        if (in[3])
          low_bits_value = 2'b11;
        else if (in[2])
          low_bits_value = 2'b10;
        else if (in[1])
          low_bits_value = 2'b01;
        else
          low_bits_value = 2'b00;
      end
      
      // 输出合并块
      always @(*) begin
        if (high_bits_valid)
          out_depth8 = {1'b1, high_bits_value};
        else
          out_depth8 = {1'b0, low_bits_value};
      end
    end
  endgenerate
  
  // 通用编码器实现
  generate
    // 通用位置优先编码器
    always @(*) begin
      out_generic = {$clog2(DEPTH){1'b0}};
      for (integer i = DEPTH-1; i >= 0; i = i-1) begin
        if (in[i]) 
          out_generic = i[$clog2(DEPTH)-1:0];
      end
    end
  endgenerate
  
  // 输出选择逻辑
  assign out = use_depth8 ? out_depth8 : out_generic;
  
endmodule