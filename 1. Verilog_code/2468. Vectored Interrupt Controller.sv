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
  integer i;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      intr_vector <= {VEC_WIDTH{1'b0}};
      valid <= 1'b0;
    end else begin
      valid <= 1'b0;
      for (i = SOURCES-1; i >= 0; i = i - 1)
        if (intr_src[i]) begin
          intr_vector <= vector_table[i*VEC_WIDTH+:VEC_WIDTH];
          valid <= 1'b1;
        end
    end
  end
endmodule