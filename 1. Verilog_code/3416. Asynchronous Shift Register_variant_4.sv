//SystemVerilog
module RD6 #(parameter WIDTH=8, DEPTH=4)(
  input wire clk,
  input wire arstn,
  input wire [WIDTH-1:0] shift_in,
  input wire input_valid,
  output wire input_ready,
  output reg [WIDTH-1:0] shift_out,
  output reg output_valid,
  input wire output_ready
);
  // Pipeline stage registers
  reg [WIDTH-1:0] pipeline_data [0:DEPTH-1];
  reg pipeline_valid [0:DEPTH-1];
  
  // Ready signal generation
  wire pipeline_ready [0:DEPTH-1];
  assign pipeline_ready[DEPTH-1] = output_ready || !pipeline_valid[DEPTH-1];
  
  genvar i;
  generate
    for (i = DEPTH-2; i >= 0; i = i - 1) begin : ready_logic
      assign pipeline_ready[i] = pipeline_ready[i+1] || !pipeline_valid[i+1];
    end
  endgenerate
  
  // Connect input stage ready signal
  assign input_ready = pipeline_ready[0];
  
  // Pipeline stage 0 (input stage)
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      pipeline_data[0] <= {WIDTH{1'b0}};
      pipeline_valid[0] <= 1'b0;
    end else if (input_valid && input_ready) begin
      pipeline_data[0] <= shift_in;
      pipeline_valid[0] <= 1'b1;
    end else if (pipeline_ready[0]) begin
      pipeline_valid[0] <= 1'b0;
    end
  end
  
  // Intermediate pipeline stages
  genvar j;
  generate
    for (j = 1; j < DEPTH; j = j + 1) begin : pipeline_stages
      always @(posedge clk or negedge arstn) begin
        if (!arstn) begin
          pipeline_data[j] <= {WIDTH{1'b0}};
          pipeline_valid[j] <= 1'b0;
        end else if (pipeline_valid[j-1] && pipeline_ready[j]) begin
          pipeline_data[j] <= pipeline_data[j-1];
          pipeline_valid[j] <= pipeline_valid[j-1];
        end else if (pipeline_ready[j]) begin
          pipeline_valid[j] <= 1'b0;
        end
      end
    end
  endgenerate
  
  // Output stage
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      shift_out <= {WIDTH{1'b0}};
      output_valid <= 1'b0;
    end else if (pipeline_valid[DEPTH-1] && output_ready) begin
      shift_out <= pipeline_data[DEPTH-1];
      output_valid <= pipeline_valid[DEPTH-1];
    end else if (output_ready) begin
      output_valid <= 1'b0;
    end
  end
endmodule