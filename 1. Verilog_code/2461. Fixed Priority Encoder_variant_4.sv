//SystemVerilog
// SystemVerilog (IEEE 1364-2005)
module fixed_priority_intr_ctrl(
  input wire clk, rst_n,
  input wire [7:0] intr_src,
  output reg [2:0] intr_id,
  output reg intr_valid
);
  // Stage 1 registers
  reg [7:0] intr_src_stage1;
  reg intr_valid_stage1;
  reg [2:0] intr_id_stage1;
  
  // Stage 2 registers
  reg intr_valid_stage2;
  reg [2:0] intr_id_stage2;
  
  // Stage 1: Capture interrupt sources and determine if any interrupt is active
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_src_stage1 <= 8'b0;
      intr_valid_stage1 <= 1'b0;
    end else begin
      intr_src_stage1 <= intr_src;
      intr_valid_stage1 <= |intr_src;
    end
  end
  
  // Stage 1: Priority encoding logic - changed to use case statement
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id_stage1 <= 3'b0;
    end else begin
      casez (intr_src)
        8'b1???????: intr_id_stage1 <= 3'd7;
        8'b01??????: intr_id_stage1 <= 3'd6;
        8'b001?????: intr_id_stage1 <= 3'd5;
        8'b0001????: intr_id_stage1 <= 3'd4;
        8'b00001???: intr_id_stage1 <= 3'd3;
        8'b000001??: intr_id_stage1 <= 3'd2;
        8'b0000001?: intr_id_stage1 <= 3'd1;
        8'b00000001: intr_id_stage1 <= 3'd0;
        default:     intr_id_stage1 <= 3'd0;
      endcase
    end
  end
  
  // Stage 2: Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id_stage2 <= 3'b0;
      intr_valid_stage2 <= 1'b0;
    end else begin
      intr_id_stage2 <= intr_id_stage1;
      intr_valid_stage2 <= intr_valid_stage1;
    end
  end
  
  // Final output assignments
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0;
      intr_valid <= 1'b0;
    end else begin
      intr_id <= intr_id_stage2;
      intr_valid <= intr_valid_stage2;
    end
  end
endmodule