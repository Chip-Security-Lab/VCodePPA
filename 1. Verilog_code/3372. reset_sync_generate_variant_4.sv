//SystemVerilog
module reset_sync_generate #(parameter NUM_STAGES=2)(
  input  wire clk,
  input  wire rst_n,
  output wire synced
);
  (* dont_touch = "true" *)
  (* shreg_extract = "no" *)
  (* async_reg = "true" *)
  reg [NUM_STAGES-1:0] sync_chain;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sync_chain <= {NUM_STAGES{1'b0}};
    end
    else begin
      sync_chain <= {sync_chain[NUM_STAGES-2:0], 1'b1};
    end
  end
  
  assign synced = sync_chain[NUM_STAGES-1];
endmodule