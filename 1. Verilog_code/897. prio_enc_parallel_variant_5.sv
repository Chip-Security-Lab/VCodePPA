//SystemVerilog
module prio_enc_parallel #(parameter N=16)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);
  
  wire [N-1:0] lead_one;
  
  // 实例化减法计算模块
  twos_comp_subtractor #(.N(N)) u_subtractor(
    .req(req),
    .mask(mask)
  );
  
  // 实例化最高位检测模块
  lead_one_detector #(.N(N)) u_lead_one_detector(
    .req(req),
    .mask(mask),
    .lead_one(lead_one)
  );
  
  // 实例化位置编码模块
  position_encoder #(.N(N)) u_position_encoder(
    .lead_one(lead_one),
    .index(index)
  );

endmodule

module twos_comp_subtractor #(parameter N=16)(
  input [N-1:0] req,
  output [N-1:0] mask
);
  
  wire [N-1:0] inverted_req;
  wire [N-1:0] ones_comp;
  wire [N-1:0] twos_comp;
  wire [N-1:0] sum;
  wire [N:0] carry;
  
  assign inverted_req = ~req;
  assign ones_comp = inverted_req;
  assign twos_comp = ones_comp + 1'b1;
  assign carry[0] = 1'b0;
  
  generate
    genvar j;
    for (j=0; j<N; j=j+1) begin: gen_add
      assign carry[j+1] = (req[j] & twos_comp[j]) | (req[j] & carry[j]) | (twos_comp[j] & carry[j]);
      assign sum[j] = req[j] ^ twos_comp[j] ^ carry[j];
    end
  endgenerate
  
  assign mask = sum;
  
endmodule

module lead_one_detector #(parameter N=16)(
  input [N-1:0] req,
  input [N-1:0] mask,
  output [N-1:0] lead_one
);
  
  assign lead_one = req & ~mask;
  
endmodule

module position_encoder #(parameter N=16)(
  input [N-1:0] lead_one,
  output reg [$clog2(N)-1:0] index
);
  
  integer i;
  always @(*) begin
    index = 0;
    for (i=0; i<N; i=i+1)
      if (lead_one[i]) index = i[$clog2(N)-1:0];
  end
  
endmodule