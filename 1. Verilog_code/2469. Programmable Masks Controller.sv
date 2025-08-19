module prog_mask_intr_ctrl(
  input wire CLK, nRST,
  input wire [7:0] INTR, MASK,
  input wire UPDATE_MASK,
  output reg [2:0] ID,
  output reg VALID
);
  reg [7:0] mask_reg;
  wire [7:0] masked_intr;
  
  assign masked_intr = INTR & mask_reg;
  
  always @(posedge CLK or negedge nRST) begin
    if (~nRST)
      mask_reg <= 8'hFF;
    else if (UPDATE_MASK)
      mask_reg <= MASK;
  end
  
  always @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      ID <= 3'd0; VALID <= 1'b0;
    end else begin
      VALID <= |masked_intr;
      casez (masked_intr)
        8'b1???????: ID <= 3'd7;
        8'b01??????: ID <= 3'd6;
        8'b001?????: ID <= 3'd5;
        8'b0001????: ID <= 3'd4;
        8'b00001???: ID <= 3'd3;
        8'b000001??: ID <= 3'd2;
        8'b0000001?: ID <= 3'd1;
        8'b00000001: ID <= 3'd0;
        default: ID <= 3'd0;
      endcase
    end
  end
endmodule