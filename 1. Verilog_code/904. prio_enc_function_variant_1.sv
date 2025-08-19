//SystemVerilog
// IEEE 1364-2005
module prio_enc_function #(parameter W=16)(
  input [W-1:0] req,
  output [$clog2(W)-1:0] enc_addr
);

  wire [W-1:0] valid_bits;
  wire [$clog2(W)-1:0] enc_results [W-1:0];
  
  genvar i;
  generate
    for (i = 0; i < W; i = i + 1) begin : gen_encodings
      assign valid_bits[i] = req[i];
      assign enc_results[i] = i[$clog2(W)-1:0];
    end
  endgenerate
  
  prio_enc_prefix_tree #(
    .WIDTH(W),
    .ADDR_WIDTH($clog2(W))
  ) prefix_tree (
    .valid_bits(valid_bits),
    .encodings(enc_results),
    .result(enc_addr)
  );
  
endmodule

module prio_enc_prefix_tree #(
  parameter WIDTH = 16,
  parameter ADDR_WIDTH = 4
)(
  input [WIDTH-1:0] valid_bits,
  input [ADDR_WIDTH-1:0] encodings [WIDTH-1:0],
  output [ADDR_WIDTH-1:0] result
);

  genvar level, i;
  generate
    if (WIDTH == 1) begin : single_bit
      reg [ADDR_WIDTH-1:0] temp_result;
      always @(*) begin
        if (valid_bits[0]) begin
          temp_result = encodings[0];
        end else begin
          temp_result = {ADDR_WIDTH{1'b0}};
        end
      end
      assign result = temp_result;
    end else begin : multi_bit
      wire [WIDTH/2-1:0] level1_valid;
      wire [ADDR_WIDTH-1:0] level1_addr [WIDTH/2-1:0];
      
      for (i = 0; i < WIDTH/2; i = i + 1) begin : level1_pairs
        reg [ADDR_WIDTH-1:0] temp_addr;
        always @(*) begin
          if (valid_bits[i*2+1]) begin
            temp_addr = encodings[i*2+1];
          end else begin
            temp_addr = encodings[i*2];
          end
        end
        assign level1_valid[i] = valid_bits[i*2] | valid_bits[i*2+1];
        assign level1_addr[i] = temp_addr;
      end
      
      wire [ADDR_WIDTH-1:0] final_level_addr;
      wire final_level_valid;
      
      recursive_priority_finder #(
        .WIDTH(WIDTH/2),
        .ADDR_WIDTH(ADDR_WIDTH)
      ) finder (
        .valid_bits(level1_valid),
        .encodings(level1_addr),
        .result_valid(final_level_valid),
        .result_addr(final_level_addr)
      );
      
      reg [ADDR_WIDTH-1:0] final_result;
      always @(*) begin
        if (final_level_valid) begin
          final_result = final_level_addr;
        end else begin
          final_result = {ADDR_WIDTH{1'b0}};
        end
      end
      assign result = final_result;
    end
  endgenerate
  
endmodule

module recursive_priority_finder #(
  parameter WIDTH = 8,
  parameter ADDR_WIDTH = 3
)(
  input [WIDTH-1:0] valid_bits,
  input [ADDR_WIDTH-1:0] encodings [WIDTH-1:0],
  output result_valid,
  output [ADDR_WIDTH-1:0] result_addr
);

  generate
    if (WIDTH == 1) begin : base_case
      assign result_valid = valid_bits[0];
      assign result_addr = encodings[0];
    end else if (WIDTH == 2) begin : two_inputs
      reg [ADDR_WIDTH-1:0] temp_addr;
      always @(*) begin
        if (valid_bits[1]) begin
          temp_addr = encodings[1];
        end else begin
          temp_addr = encodings[0];
        end
      end
      assign result_valid = valid_bits[0] | valid_bits[1];
      assign result_addr = temp_addr;
    end else begin : recursive_case
      localparam HALF = WIDTH / 2;
      
      wire [HALF-1:0] upper_valid, lower_valid;
      wire [ADDR_WIDTH-1:0] upper_encodings [HALF-1:0];
      wire [ADDR_WIDTH-1:0] lower_encodings [WIDTH-HALF-1:0];
      
      genvar i;
      for (i = 0; i < HALF; i = i + 1) begin : split_upper
        assign upper_valid[i] = valid_bits[HALF+i];
        assign upper_encodings[i] = encodings[HALF+i];
      end
      
      for (i = 0; i < WIDTH-HALF; i = i + 1) begin : split_lower
        assign lower_valid[i] = valid_bits[i];
        assign lower_encodings[i] = encodings[i];
      end
      
      wire upper_result_valid;
      wire [ADDR_WIDTH-1:0] upper_result_addr;
      recursive_priority_finder #(
        .WIDTH(HALF),
        .ADDR_WIDTH(ADDR_WIDTH)
      ) upper_finder (
        .valid_bits(upper_valid),
        .encodings(upper_encodings),
        .result_valid(upper_result_valid),
        .result_addr(upper_result_addr)
      );
      
      wire lower_result_valid;
      wire [ADDR_WIDTH-1:0] lower_result_addr;
      recursive_priority_finder #(
        .WIDTH(WIDTH-HALF),
        .ADDR_WIDTH(ADDR_WIDTH)
      ) lower_finder (
        .valid_bits(lower_valid),
        .encodings(lower_encodings),
        .result_valid(lower_result_valid),
        .result_addr(lower_result_addr)
      );
      
      reg [ADDR_WIDTH-1:0] final_addr;
      always @(*) begin
        if (upper_result_valid) begin
          final_addr = upper_result_addr;
        end else begin
          final_addr = lower_result_addr;
        end
      end
      assign result_valid = upper_result_valid | lower_result_valid;
      assign result_addr = final_addr;
    end
  endgenerate
  
endmodule