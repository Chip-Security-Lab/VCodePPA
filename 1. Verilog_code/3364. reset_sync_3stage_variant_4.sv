//SystemVerilog
module reset_sync_3stage (
  input  wire clk,    // Clock input
  input  wire rst_n,  // Asynchronous reset (active low)
  output wire synced_rst // Synchronized reset output
);
  (* dont_touch = "true" *) (* shreg_extract = "no" *)
  reg [2:0] sync_stages;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_stages <= 3'b000;
    end else begin
      sync_stages <= {sync_stages[1:0], 1'b1};
    end
  end
  
  assign synced_rst = sync_stages[2];
  
endmodule