//SystemVerilog
// IEEE 1364-2005 Verilog
module prio_enc_dynamic_mask #(parameter W=8)(
  input wire clk,
  input wire rst_n,
  input wire valid_in,
  input wire [W-1:0] mask,
  input wire [W-1:0] req,
  output reg [$clog2(W)-1:0] index,
  output reg valid_out
);

  // Pipeline stage 1 signals
  wire [W-1:0] mask_stage1;
  wire [W-1:0] req_stage1;
  wire valid_stage1;
  
  // Pipeline stage 2 signals
  wire [W-1:0] masked_req_stage2;
  wire valid_stage2;
  
  // Pipeline stage 3 signals
  wire [$clog2(W)-1:0] next_index;

  // Stage 1: Input register
  input_reg #(.W(W)) u_input_reg (
    .clk(clk),
    .rst_n(rst_n),
    .mask_in(mask),
    .req_in(req),
    .valid_in(valid_in),
    .mask_out(mask_stage1),
    .req_out(req_stage1),
    .valid_out(valid_stage1)
  );

  // Stage 2: Masking logic
  mask_logic #(.W(W)) u_mask_logic (
    .clk(clk),
    .rst_n(rst_n),
    .mask_in(mask_stage1),
    .req_in(req_stage1),
    .valid_in(valid_stage1),
    .masked_req_out(masked_req_stage2),
    .valid_out(valid_stage2)
  );

  // Stage 3: Priority encoder
  prio_encoder #(.W(W)) u_prio_encoder (
    .masked_req(masked_req_stage2),
    .index(next_index)
  );

  // Stage 4: Output register
  output_reg #(.W(W)) u_output_reg (
    .clk(clk),
    .rst_n(rst_n),
    .index_in(next_index),
    .valid_in(valid_stage2),
    .index_out(index),
    .valid_out(valid_out)
  );

endmodule

// Input register module
module input_reg #(parameter W=8)(
  input wire clk,
  input wire rst_n,
  input wire [W-1:0] mask_in,
  input wire [W-1:0] req_in,
  input wire valid_in,
  output reg [W-1:0] mask_out,
  output reg [W-1:0] req_out,
  output reg valid_out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mask_out <= {W{1'b0}};
      req_out <= {W{1'b0}};
      valid_out <= 1'b0;
    end else begin
      mask_out <= mask_in;
      req_out <= req_in;
      valid_out <= valid_in;
    end
  end

endmodule

// Masking logic module
module mask_logic #(parameter W=8)(
  input wire clk,
  input wire rst_n,
  input wire [W-1:0] mask_in,
  input wire [W-1:0] req_in,
  input wire valid_in,
  output reg [W-1:0] masked_req_out,
  output reg valid_out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      masked_req_out <= {W{1'b0}};
      valid_out <= 1'b0;
    end else begin
      masked_req_out <= req_in & mask_in;
      valid_out <= valid_in;
    end
  end

endmodule

// Priority encoder module
module prio_encoder #(parameter W=8)(
  input wire [W-1:0] masked_req,
  output reg [$clog2(W)-1:0] index
);

  always @(*) begin
    index = {$clog2(W){1'b0}};
    for(integer i=W-1; i>=0; i=i-1)
      if(masked_req[i]) index = i[$clog2(W)-1:0];
  end

endmodule

// Output register module
module output_reg #(parameter W=8)(
  input wire clk,
  input wire rst_n,
  input wire [$clog2(W)-1:0] index_in,
  input wire valid_in,
  output reg [$clog2(W)-1:0] index_out,
  output reg valid_out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      index_out <= {$clog2(W){1'b0}};
      valid_out <= 1'b0;
    end else begin
      index_out <= index_in;
      valid_out <= valid_in;
    end
  end

endmodule