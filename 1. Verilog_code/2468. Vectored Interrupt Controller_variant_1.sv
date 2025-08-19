//SystemVerilog
module vectored_intr_ctrl #(
  parameter SOURCES = 16,
  parameter VEC_WIDTH = 8
)(
  input clk, rstn,
  input [SOURCES-1:0] intr_src,
  input [SOURCES*VEC_WIDTH-1:0] vector_table,
  output reg [VEC_WIDTH-1:0] intr_vector,
  output reg valid
);
  // Combinational signals for first stage processing
  wire [SOURCES-1:0] intr_valid_comb;
  wire [SOURCES*VEC_WIDTH-1:0] selected_vectors_comb;
  
  // Internal signals for priority resolution
  reg [SOURCES-1:0] intr_src_reg;
  reg [SOURCES-1:0] intr_priority;
  reg [VEC_WIDTH-1:0] selected_vector;
  reg has_interrupt;
  
  integer i;
  
  // Combinational logic to detect interrupts and select vectors
  assign intr_valid_comb = intr_src;
  
  // Generate selected vectors combinationally
  genvar g;
  generate
    for (g = 0; g < SOURCES; g = g + 1) begin : gen_vector_select
      assign selected_vectors_comb[g*VEC_WIDTH+:VEC_WIDTH] = 
             intr_src[g] ? vector_table[g*VEC_WIDTH+:VEC_WIDTH] : {VEC_WIDTH{1'b0}};
    end
  endgenerate
  
  // First stage: register pre-processed interrupt signals
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      intr_src_reg <= {SOURCES{1'b0}};
    end else begin
      intr_src_reg <= intr_src;
    end
  end
  
  // Priority resolution logic (combinational)
  always @(*) begin
    intr_priority = {SOURCES{1'b0}};
    selected_vector = {VEC_WIDTH{1'b0}};
    has_interrupt = 1'b0;
    
    for (i = SOURCES-1; i >= 0; i = i - 1) begin
      if (intr_valid_comb[i]) begin
        intr_priority[i] = 1'b1;
        selected_vector = selected_vectors_comb[i*VEC_WIDTH+:VEC_WIDTH];
        has_interrupt = 1'b1;
      end
    end
  end
  
  // Second stage: register outputs
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      intr_vector <= {VEC_WIDTH{1'b0}};
      valid <= 1'b0;
    end else begin
      valid <= has_interrupt;
      intr_vector <= selected_vector;
    end
  end
endmodule