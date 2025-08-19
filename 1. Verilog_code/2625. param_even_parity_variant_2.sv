//SystemVerilog
module param_even_parity #(
  parameter WIDTH = 16
)(
  input [WIDTH-1:0] data_bus,
  output reg parity_bit
);

  // 使用优化的树形结构实现偶校验
  always @(*) begin
    case (WIDTH)
      1: parity_bit = data_bus[0];
      2: parity_bit = data_bus[0] ^ data_bus[1];
      4: parity_bit = (data_bus[0] ^ data_bus[1]) ^ (data_bus[2] ^ data_bus[3]);
      8: begin
        reg [1:0] stage1;
        stage1[0] = (data_bus[0] ^ data_bus[1]) ^ (data_bus[2] ^ data_bus[3]);
        stage1[1] = (data_bus[4] ^ data_bus[5]) ^ (data_bus[6] ^ data_bus[7]);
        parity_bit = stage1[0] ^ stage1[1];
      end
      16: begin
        reg [1:0] stage1, stage2;
        stage1[0] = (data_bus[0] ^ data_bus[1]) ^ (data_bus[2] ^ data_bus[3]);
        stage1[1] = (data_bus[4] ^ data_bus[5]) ^ (data_bus[6] ^ data_bus[7]);
        stage2[0] = (data_bus[8] ^ data_bus[9]) ^ (data_bus[10] ^ data_bus[11]);
        stage2[1] = (data_bus[12] ^ data_bus[13]) ^ (data_bus[14] ^ data_bus[15]);
        parity_bit = (stage1[0] ^ stage1[1]) ^ (stage2[0] ^ stage2[1]);
      end
      32: begin
        reg [1:0] stage1, stage2, stage3, stage4;
        reg [1:0] final_stage;
        
        stage1[0] = (data_bus[0] ^ data_bus[1]) ^ (data_bus[2] ^ data_bus[3]);
        stage1[1] = (data_bus[4] ^ data_bus[5]) ^ (data_bus[6] ^ data_bus[7]);
        stage2[0] = (data_bus[8] ^ data_bus[9]) ^ (data_bus[10] ^ data_bus[11]);
        stage2[1] = (data_bus[12] ^ data_bus[13]) ^ (data_bus[14] ^ data_bus[15]);
        stage3[0] = (data_bus[16] ^ data_bus[17]) ^ (data_bus[18] ^ data_bus[19]);
        stage3[1] = (data_bus[20] ^ data_bus[21]) ^ (data_bus[22] ^ data_bus[23]);
        stage4[0] = (data_bus[24] ^ data_bus[25]) ^ (data_bus[26] ^ data_bus[27]);
        stage4[1] = (data_bus[28] ^ data_bus[29]) ^ (data_bus[30] ^ data_bus[31]);
        
        final_stage[0] = (stage1[0] ^ stage1[1]) ^ (stage2[0] ^ stage2[1]);
        final_stage[1] = (stage3[0] ^ stage3[1]) ^ (stage4[0] ^ stage4[1]);
        
        parity_bit = final_stage[0] ^ final_stage[1];
      end
      default: begin
        reg [WIDTH-1:0] temp;
        integer i;
        temp = data_bus;
        for(i = 1; i < WIDTH; i = i << 1) begin
          temp = temp ^ (temp >> i);
        end
        parity_bit = temp[0];
      end
    endcase
  end
  
endmodule