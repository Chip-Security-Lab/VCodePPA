//SystemVerilog
// Top-level module
module reset_synchronizer (
  input  wire clk,
  input  wire async_reset_n,
  output wire sync_reset_n
);
  
  // Internal connections
  wire meta_stage_out;
  
  // Instantiate the metastability capture stage
  reset_meta_stage meta_stage (
    .clk           (clk),
    .async_reset_n (async_reset_n),
    .meta_out      (meta_stage_out)
  );
  
  // Instantiate the synchronization output stage
  reset_sync_stage sync_stage (
    .clk           (clk),
    .async_reset_n (async_reset_n),
    .meta_in       (meta_stage_out),
    .sync_reset_n  (sync_reset_n)
  );
  
endmodule

// First stage of reset synchronizer - captures metastability
module reset_meta_stage (
  input  wire clk,
  input  wire async_reset_n,
  output reg  meta_out
);
  
  // Prevent optimization of metastability capture register
  (* dont_touch = "true" *)
  
  // Asynchronous reset, synchronous release
  always @(posedge clk or negedge async_reset_n) begin
    if (~async_reset_n) begin
      meta_out <= 1'b0;
    end else begin
      meta_out <= 1'b1;
    end
  end
  
endmodule

// Second stage of reset synchronizer - generates stable output
module reset_sync_stage (
  input  wire clk,
  input  wire async_reset_n,
  input  wire meta_in,
  output reg  sync_reset_n
);
  
  // Asynchronous reset, synchronous release
  always @(posedge clk or negedge async_reset_n) begin
    if (~async_reset_n) begin
      sync_reset_n <= 1'b0;
    end else begin
      sync_reset_n <= meta_in;
    end
  end
  
endmodule