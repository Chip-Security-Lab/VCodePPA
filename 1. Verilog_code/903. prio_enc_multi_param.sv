module prio_enc_multi_param #(
  parameter DATA_BITS = 10,
  parameter ADDR_BITS = 4
)(
  input enable,
  input [DATA_BITS-1:0] data_input,
  output reg [ADDR_BITS-1:0] prio_index
);
integer i;
always @(*) begin
  prio_index = 0;
  if(enable) begin
    for(i=DATA_BITS-1; i>=0; i=i-1)
      if(data_input[i]) prio_index = i[ADDR_BITS-1:0];
  end
end
endmodule