//SystemVerilog
// SystemVerilog
module dual_reset_counter #(parameter WIDTH = 8)(
  input clk, sync_rst, async_rst_n, enable,
  output reg [WIDTH-1:0] count,
  output reg count_valid
);
  
  // Clock buffering for high fanout reduction
  (* dont_touch = "true" *) reg clk_buf1, clk_buf2, clk_buf3;
  
  // Reset signal buffering
  (* dont_touch = "true" *) reg async_rst_n_buf1, async_rst_n_buf2, async_rst_n_buf3;
  
  // Pipeline stage 1 signals
  reg stage1_valid;
  reg [WIDTH-1:0] stage1_count;
  
  // Pipeline stage 2 signals
  reg stage2_valid;
  reg [WIDTH-1:0] stage2_count;
  
  // Pipeline control signals
  wire reset_condition;
  wire update_condition;
  
  // Fanout reduction for clock signal
  always @(posedge clk) begin
    clk_buf1 <= 1'b1;
    clk_buf2 <= 1'b1;
    clk_buf3 <= 1'b1;
  end
  
  // Fanout reduction for async reset signal
  always @(*) begin
    async_rst_n_buf1 = async_rst_n;
    async_rst_n_buf2 = async_rst_n;
    async_rst_n_buf3 = async_rst_n;
  end
  
  // Distribute control signals to reduce logic depth
  assign reset_condition = !async_rst_n_buf1 | sync_rst;
  assign update_condition = enable & !reset_condition;
  
  // Stage 1: Input capture and increment calculation
  always @(posedge clk_buf1 or negedge async_rst_n_buf1) begin
    if (!async_rst_n_buf1) begin
      stage1_valid <= 1'b0;
      stage1_count <= {WIDTH{1'b0}};
    end
    else if (sync_rst) begin
      stage1_valid <= 1'b0;
      stage1_count <= {WIDTH{1'b0}};
    end
    else if (update_condition) begin
      stage1_valid <= 1'b1;
      stage1_count <= count + 1'b1;
    end
    else begin
      stage1_valid <= 1'b0;
      stage1_count <= stage1_count;
    end
  end
  
  // Stage 2: Result processing
  always @(posedge clk_buf2 or negedge async_rst_n_buf2) begin
    if (!async_rst_n_buf2) begin
      stage2_valid <= 1'b0;
      stage2_count <= {WIDTH{1'b0}};
    end
    else if (sync_rst) begin
      stage2_valid <= 1'b0;
      stage2_count <= {WIDTH{1'b0}};
    end
    else begin
      stage2_valid <= stage1_valid;
      stage2_count <= stage1_count;
    end
  end
  
  // Output stage: Register final result
  always @(posedge clk_buf3 or negedge async_rst_n_buf3) begin
    if (!async_rst_n_buf3) begin
      count <= {WIDTH{1'b0}};
      count_valid <= 1'b0;
    end
    else if (sync_rst) begin
      count <= {WIDTH{1'b0}};
      count_valid <= 1'b0;
    end
    else if (stage2_valid) begin
      count <= stage2_count;
      count_valid <= 1'b1;
    end
    else begin
      count <= count;
      count_valid <= 1'b0;
    end
  end
endmodule