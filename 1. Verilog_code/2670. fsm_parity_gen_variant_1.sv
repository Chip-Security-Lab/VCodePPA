//SystemVerilog
module brent_kung_adder(
  input [15:0] a, b,
  output [15:0] sum,
  output cout
);

  // Generate and propagate signals
  wire [15:0] g, p;
  assign g = a & b;
  assign p = a ^ b;

  // First level - 4-bit groups
  wire [3:0] g1, p1;
  genvar i;
  generate
    for(i=0; i<4; i=i+1) begin: gen_first
      assign g1[i] = g[i*4+3] | (p[i*4+3] & g[i*4+2]) | 
                    (p[i*4+3] & p[i*4+2] & g[i*4+1]) |
                    (p[i*4+3] & p[i*4+2] & p[i*4+1] & g[i*4]);
      assign p1[i] = p[i*4+3] & p[i*4+2] & p[i*4+1] & p[i*4];
    end
  endgenerate

  // Second level - 16-bit group
  wire g2, p2;
  assign g2 = g1[3] | (p1[3] & g1[2]) | (p1[3] & p1[2] & g1[1]) |
              (p1[3] & p1[2] & p1[1] & g1[0]);
  assign p2 = p1[3] & p1[2] & p1[1] & p1[0];

  // Carry generation
  wire [15:0] c;
  assign c[0] = 1'b0;
  assign c[1] = g[0];
  assign c[2] = g[1] | (p[1] & g[0]);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
  
  genvar j;
  generate
    for(j=4; j<16; j=j+1) begin: gen_carry
      assign c[j] = g[j-1] | (p[j-1] & c[j-1]);
    end
  endgenerate

  // Sum generation
  assign sum = p ^ c;
  assign cout = c[15];

endmodule

module fsm_parity_gen(
  input clk, rst, start,
  input [15:0] data_in,
  output reg valid,
  output reg parity_bit
);

  localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;
  
  reg [1:0] state;
  reg [3:0] bit_pos;
  reg parity_calc;
  wire [15:0] sum;
  wire cout;
  
  brent_kung_adder adder_inst(
    .a(data_in),
    .b({15'b0, parity_calc}),
    .sum(sum),
    .cout(cout)
  );

  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      bit_pos <= 4'd0;
      parity_bit <= 1'b0;
      valid <= 1'b0;
      parity_calc <= 1'b0;
    end else begin
      valid <= 1'b0;
      
      case (state)
        IDLE: begin
          if (start) begin
            state <= COMPUTE;
            bit_pos <= 4'd0;
            parity_calc <= 1'b0;
          end
        end
        
        COMPUTE: begin
          if (bit_pos == 4'd15) begin
            parity_calc <= sum[15];
            parity_bit <= sum[15];
            state <= DONE;
          end else begin
            parity_calc <= sum[bit_pos];
            bit_pos <= bit_pos + 1'b1;
          end
        end
        
        DONE: begin
          valid <= 1'b1;
          state <= IDLE;
        end
        
        default: state <= IDLE;
      endcase
    end
  end
endmodule