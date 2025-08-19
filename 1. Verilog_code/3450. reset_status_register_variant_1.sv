//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_status_register (
  input wire clk,
  input wire clear,
  input wire pwr_rst,
  input wire wdt_rst,
  input wire sw_rst,
  input wire ext_rst,
  input wire valid_in,
  output reg valid_out,
  output reg [7:0] rst_status
);

  // Stage 1 registers
  reg [7:0] rst_status_stage1;
  reg valid_stage1;
  reg wdt_rst_stage1, sw_rst_stage1, ext_rst_stage1, clear_stage1;

  // Stage 2 registers
  reg [7:0] rst_status_stage2;
  reg valid_stage2;
  
  // Reset handling for stage 1 control signals
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      valid_stage1 <= 1'b0;
      wdt_rst_stage1 <= 1'b0;
      sw_rst_stage1 <= 1'b0;
      ext_rst_stage1 <= 1'b0;
      clear_stage1 <= 1'b0;
    end else if (valid_in) begin
      clear_stage1 <= clear;
      wdt_rst_stage1 <= wdt_rst;
      sw_rst_stage1 <= sw_rst;
      ext_rst_stage1 <= ext_rst;
      valid_stage1 <= 1'b1;
    end else begin
      valid_stage1 <= 1'b0;
    end
  end
  
  // Stage 1 status register processing
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      rst_status_stage1 <= 8'h01;
    end else if (valid_in) begin
      if (clear) begin
        rst_status_stage1 <= 8'h00;
      end else begin
        rst_status_stage1 <= rst_status;
        if (wdt_rst) rst_status_stage1[1] <= 1'b1;
        if (sw_rst) rst_status_stage1[2] <= 1'b1;
        if (ext_rst) rst_status_stage1[3] <= 1'b1;
      end
    end
  end

  // Reset handling for stage 2 control signals
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      valid_stage2 <= 1'b0;
    end else begin
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Stage 2 status register processing
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      rst_status_stage2 <= 8'h01;
    end else if (valid_stage1) begin
      if (clear_stage1) begin
        rst_status_stage2 <= 8'h00;
      end else begin
        rst_status_stage2 <= rst_status_stage1;
      end
    end
  end

  // Final output valid signal
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      valid_out <= 1'b0;
    end else begin
      valid_out <= valid_stage2;
    end
  end
  
  // Final output status register
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      rst_status <= 8'h01;
    end else if (valid_stage2) begin
      rst_status <= rst_status_stage2;
    end
  end

endmodule