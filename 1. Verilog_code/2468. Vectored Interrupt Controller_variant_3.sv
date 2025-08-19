//SystemVerilog
module vectored_intr_ctrl #(
  parameter SOURCES = 16,
  parameter VEC_WIDTH = 8
)(
  input wire clk, rstn,
  input wire [SOURCES-1:0] intr_src,
  input wire [SOURCES*VEC_WIDTH-1:0] vector_table,
  output reg [VEC_WIDTH-1:0] intr_vector,
  output reg valid
);
  
  reg [VEC_WIDTH-1:0] next_intr_vector;
  reg next_valid;
  reg [$clog2(SOURCES)-1:0] highest_prio_idx;
  reg found_active;
  
  always @(*) begin
    found_active = 1'b0;
    highest_prio_idx = {$clog2(SOURCES){1'b0}};
    next_valid = 1'b0;
    next_intr_vector = intr_vector; // Default: hold current value
    
    // Priority encoder implementation - find highest priority (largest index) interrupt
    for (int i = 0; i < SOURCES; i = i + 1) begin
      if (intr_src[i] && !found_active) begin
        highest_prio_idx = i;
        found_active = 1'b1;
      end
    end
    
    // Set output values based on priority encoding result
    if (found_active) begin
      next_intr_vector = vector_table[highest_prio_idx*VEC_WIDTH+:VEC_WIDTH];
      next_valid = 1'b1;
    end
  end
  
  // Register updates
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      intr_vector <= {VEC_WIDTH{1'b0}};
      valid <= 1'b0;
    end else begin
      intr_vector <= next_intr_vector;
      valid <= next_valid;
    end
  end
  
endmodule