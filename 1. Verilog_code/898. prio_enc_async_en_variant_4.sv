//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准
// 顶层模块
module prio_enc_async_en #(parameter BITS=4)(
  input arst, en,
  input [BITS-1:0] din,
  output [$clog2(BITS)-1:0] dout
);
  
  wire [$clog2(BITS)-1:0] encoded_value;
  wire valid_input;
  
  // 输入使能控制
  input_controller #(.BITS(BITS)) u_input_ctrl (
    .arst(arst),
    .en(en),
    .valid_input(valid_input)
  );
  
  // 优先编码逻辑
  priority_encoder #(.BITS(BITS)) u_prio_enc (
    .din(din),
    .encoded_value(encoded_value)
  );
  
  // 输出选择逻辑
  output_selector #(.BITS(BITS)) u_out_sel (
    .arst(arst),
    .valid_input(valid_input),
    .encoded_value(encoded_value),
    .dout(dout)
  );
  
endmodule

// 输入控制器子模块
module input_controller #(parameter BITS=4)(
  input arst, en,
  output valid_input
);
  
  assign valid_input = !arst && en;
  
endmodule

// 优先编码器子模块
module priority_encoder #(parameter BITS=4)(
  input [BITS-1:0] din,
  output [$clog2(BITS)-1:0] encoded_value
);
  
  generate
    if (BITS == 2) begin: gen_2bit
      reg encoded_value_reg;
      
      always @(*) begin
        if (din[1]) begin
          encoded_value_reg = 1'b1;
        end else begin
          encoded_value_reg = 1'b0;
        end
      end
      
      assign encoded_value = encoded_value_reg;
    end
    else if (BITS == 4) begin: gen_4bit
      reg [1:0] result;
      always @(*) begin
        casez (din)
          4'b1???: result = 2'b11;
          4'b01??: result = 2'b10;
          4'b001?: result = 2'b01;
          4'b0001: result = 2'b00;
          default: result = 2'b00;
        endcase
      end
      assign encoded_value = result;
    end
    else if (BITS == 8) begin: gen_8bit
      reg [2:0] result;
      always @(*) begin
        casez (din)
          8'b1???????: result = 3'b111;
          8'b01??????: result = 3'b110;
          8'b001?????: result = 3'b101;
          8'b0001????: result = 3'b100;
          8'b00001???: result = 3'b011;
          8'b000001??: result = 3'b010;
          8'b0000001?: result = 3'b001;
          8'b00000001: result = 3'b000;
          default: result = 3'b000;
        endcase
      end
      assign encoded_value = result;
    end
    else begin: gen_default
      reg [$clog2(BITS)-1:0] result;
      
      integer i;
      always @(*) begin
        result = {$clog2(BITS){1'b0}};
        for(i=0; i<BITS; i=i+1) begin
          if(din[i]) result = i[$clog2(BITS)-1:0];
        end
      end
      assign encoded_value = result;
    end
  endgenerate
  
endmodule

// 输出选择器子模块
module output_selector #(parameter BITS=4)(
  input arst,
  input valid_input,
  input [$clog2(BITS)-1:0] encoded_value,
  output reg [$clog2(BITS)-1:0] dout
);
  
  always @(*) begin
    if (arst) begin
      dout = {$clog2(BITS){1'b0}};
    end else begin
      if (valid_input) begin
        dout = encoded_value;
      end else begin
        dout = {$clog2(BITS){1'b0}};
      end
    end
  end
  
endmodule