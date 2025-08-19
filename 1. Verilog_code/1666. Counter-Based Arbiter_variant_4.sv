//SystemVerilog
module booth_multiplier(
  input wire clock, reset,
  input wire [3:0] multiplicand,
  input wire [3:0] multiplier,
  output reg [7:0] product
);

  reg [3:0] A;
  reg [3:0] Q;
  reg Q_1;
  reg [1:0] count;
  reg [7:0] P;

  always @(posedge clock) begin
    if (reset) begin
      A <= 4'b0;
      Q <= multiplier;
      Q_1 <= 1'b0;
      count <= 2'b0;
      P <= 8'b0;
    end else begin
      if (count < 2'b11) begin
        case ({Q[0], Q_1})
          2'b00: begin
            {A, Q, Q_1} <= {A[3], A, Q};
          end
          2'b01: begin
            {A, Q, Q_1} <= {A + multiplicand, Q, Q_1};
            {A, Q, Q_1} <= {A[3], A, Q};
          end
          2'b10: begin
            {A, Q, Q_1} <= {A - multiplicand, Q, Q_1};
            {A, Q, Q_1} <= {A[3], A, Q};
          end
          2'b11: begin
            {A, Q, Q_1} <= {A[3], A, Q};
          end
        endcase
        count <= count + 1'b1;
      end else begin
        P <= {A, Q};
      end
    end
  end

  assign product = P;

endmodule

module counter_arbiter(
  input wire clock, reset,
  input wire [3:0] requests,
  output reg [3:0] grants
);

  reg [1:0] count;
  reg [3:0] barrel_shift;
  wire [7:0] booth_product;
  
  booth_multiplier booth_inst(
    .clock(clock),
    .reset(reset),
    .multiplicand(4'b0001),
    .multiplier({2'b00, count}),
    .product(booth_product)
  );
  
  always @(*) begin
    barrel_shift = booth_product[3:0];
  end
  
  always @(posedge clock) begin
    if (reset) begin
      count <= 2'b00;
      grants <= 4'b0000;
    end else begin
      if (requests[count]) begin
        grants <= barrel_shift;
      end else begin
        grants <= 4'b0000;
      end
      count <= count + 1'b1;
    end
  end
endmodule