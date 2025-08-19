module config_priority_intr_ctrl(
  input clk, async_rst_n, sync_rst,
  input [15:0] intr_sources,
  input [15:0] intr_mask,
  input [63:0] priority_config, // 4 bits per interrupt
  output reg [3:0] intr_id,
  output reg intr_active
);
  reg [3:0] highest_pri;
  reg [15:0] masked_src;
  integer i;
  
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      intr_id <= 4'd0; intr_active <= 1'b0;
    end else if (sync_rst) begin
      intr_id <= 4'd0; intr_active <= 1'b0;
    end else begin
      masked_src = intr_sources & intr_mask;
      intr_active = |masked_src;
      highest_pri = 4'hF;
      for (i = 0; i < 16; i = i + 1)
        if (masked_src[i] && priority_config[i*4+:4] < highest_pri) begin
          highest_pri = priority_config[i*4+:4];
          intr_id = i[3:0];
        end
    end
  end
endmodule