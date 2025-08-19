module reset_sync_generate #(parameter NUM_STAGES=2)(
  input  wire clk,
  input  wire rst_n,
  output wire synced
);
  reg [NUM_STAGES-1:0] chain;
  genvar i;
  generate
    for(i=0; i<NUM_STAGES; i=i+1) begin : sync_stages
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n) chain[i] <= 1'b0;
        else if(i==0) chain[i] <= 1'b1;
        else chain[i] <= chain[i-1];
      end
    end
  endgenerate
  assign synced = chain[NUM_STAGES-1];
endmodule
