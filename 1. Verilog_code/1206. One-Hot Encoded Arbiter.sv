module one_hot_arbiter(
  input wire clock, clear,
  input wire enable,
  input wire [7:0] requests,
  output reg [7:0] grants
);
  reg [7:0] priority_mask;
  
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      grants <= 8'h00;
      priority_mask <= 8'h01;
    end
    else if (enable) begin
      grants <= 8'h00;
      casez (requests & ~priority_mask)
        8'b???????1: grants <= 8'b00000001;
        8'b??????10: grants <= 8'b00000010;
        8'b?????100: grants <= 8'b00000100;
        8'b????1000: grants <= 8'b00001000;
        8'b???10000: grants <= 8'b00010000;
        8'b??100000: grants <= 8'b00100000;
        8'b?1000000: grants <= 8'b01000000;
        8'b10000000: grants <= 8'b10000000;
        default: casez (requests)
          8'b???????1: grants <= 8'b00000001;
          8'b??????10: grants <= 8'b00000010;
          8'b?????100: grants <= 8'b00000100;
          8'b????1000: grants <= 8'b00001000;
          8'b???10000: grants <= 8'b00010000;
          8'b??100000: grants <= 8'b00100000;
          8'b?1000000: grants <= 8'b01000000;
          8'b10000000: grants <= 8'b10000000;
          default: grants <= 8'h00;
        endcase
      endcase
      if (|grants) priority_mask <= {grants[6:0], grants[7]};
    end
  end
endmodule