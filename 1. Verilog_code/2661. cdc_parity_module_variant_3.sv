//SystemVerilog
module cdc_parity_module(
  input src_clk, dst_clk, src_rst_n,
  input [7:0] src_data,
  output reg dst_parity
);
  // Source domain pipelining
  reg [7:0] src_data_stage1;
  reg [7:0] src_data_stage2;
  reg [3:0] src_data_parity_stage1;
  reg [3:0] src_data_parity_stage2;
  reg [1:0] src_data_parity_stage3;
  reg [1:0] src_data_parity_stage4;
  reg src_parity_stage1;
  reg src_parity_final;
  
  // Destination domain sync and pipeline registers
  reg [3:0] sync_reg;
  reg dst_parity_stage1;
  reg dst_parity_stage2;
  
  // Source domain pipeline - Stage 1: Register input
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_data_stage1 <= 8'h0;
    end else begin
      src_data_stage1 <= src_data;
    end
  end
  
  // Source domain pipeline - Stage 2: Register again for timing improvement
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_data_stage2 <= 8'h0;
    end else begin
      src_data_stage2 <= src_data_stage1;
    end
  end
  
  // Source domain pipeline - Stage 3: Calculate partial parities
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_data_parity_stage1 <= 4'h0;
    end else begin
      src_data_parity_stage1[0] <= src_data_stage2[0] ^ src_data_stage2[1];
      src_data_parity_stage1[1] <= src_data_stage2[2] ^ src_data_stage2[3];
      src_data_parity_stage1[2] <= src_data_stage2[4] ^ src_data_stage2[5];
      src_data_parity_stage1[3] <= src_data_stage2[6] ^ src_data_stage2[7];
    end
  end
  
  // Source domain pipeline - Stage 4: Register partial parities
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_data_parity_stage2 <= 4'h0;
    end else begin
      src_data_parity_stage2 <= src_data_parity_stage1;
    end
  end
  
  // Source domain pipeline - Stage 5: Combine partial parities first level
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_data_parity_stage3 <= 2'b0;
    end else begin
      src_data_parity_stage3[0] <= src_data_parity_stage2[0] ^ src_data_parity_stage2[1];
      src_data_parity_stage3[1] <= src_data_parity_stage2[2] ^ src_data_parity_stage2[3];
    end
  end
  
  // Source domain pipeline - Stage 6: Register combined parities
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_data_parity_stage4 <= 2'b0;
    end else begin
      src_data_parity_stage4 <= src_data_parity_stage3;
    end
  end
  
  // Source domain pipeline - Stage 7: Calculate final parity
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n)
      src_parity_stage1 <= 1'b0;
    else
      src_parity_stage1 <= src_data_parity_stage4[0] ^ src_data_parity_stage4[1];
  end
  
  // Source domain pipeline - Stage 8: Register final parity
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n)
      src_parity_final <= 1'b0;
    else
      src_parity_final <= src_parity_stage1;
  end
  
  // Clock domain crossing with synchronizer
  always @(posedge dst_clk) begin
    sync_reg <= {sync_reg[2:0], src_parity_final};
  end
  
  // Destination domain pipeline - Stage 1
  always @(posedge dst_clk) begin
    dst_parity_stage1 <= sync_reg[3];
  end
  
  // Destination domain pipeline - Stage 2
  always @(posedge dst_clk) begin
    dst_parity_stage2 <= dst_parity_stage1;
  end
  
  // Destination domain pipeline - Final stage
  always @(posedge dst_clk) begin
    dst_parity <= dst_parity_stage2;
  end
endmodule