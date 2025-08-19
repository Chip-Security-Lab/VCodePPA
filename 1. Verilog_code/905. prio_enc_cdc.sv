module prio_enc_cdc #(parameter DW=16)(
  input clkA, clkB, rst,
  input [DW-1:0] data_in,
  output reg [$clog2(DW)-1:0] sync_out
);
reg [DW-1:0] sync_reg1, sync_reg2;
integer i;

// 增加两级同步器提高稳定性
always @(posedge clkA) sync_reg1 <= data_in;
always @(posedge clkB) sync_reg2 <= sync_reg1;

always @(posedge clkB) begin
  if(rst) sync_out <= 0;
  else begin
    sync_out <= 0;
    for(i=0; i<DW; i=i+1)
      if(sync_reg2[i]) sync_out <= i[$clog2(DW)-1:0];
  end
end
endmodule