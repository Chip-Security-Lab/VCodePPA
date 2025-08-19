//SystemVerilog
module fcfs_arbiter #(parameter PORTS = 4) (
  input wire clk, rst_n,
  input wire [PORTS-1:0] req,
  input wire [PORTS-1:0] done,
  output reg [PORTS-1:0] grant
);

  reg [PORTS-1:0] queue [0:PORTS-1];
  reg [2:0] head, tail;
  reg [2:0] next_head;
  wire [2:0] head_plus_1;
  wire [2:0] head_minus_1;
  wire head_gt_0;
  
  // Carry Lookahead Adder for head-1
  wire [2:0] head_inv = ~head;
  wire [2:0] carry_gen = head & head_inv;
  wire [2:0] carry_prop = head ^ head_inv;
  wire [2:0] carry = {carry_gen[2] | (carry_prop[2] & carry_gen[1]) | 
                     (carry_prop[2] & carry_prop[1] & carry_gen[0]),
                     carry_gen[1] | (carry_prop[1] & carry_gen[0]),
                     carry_gen[0]};
  assign head_minus_1 = (head_gt_0) ? (head_inv ^ carry) : (PORTS - 1);
  assign head_gt_0 = (head != 0);
  
  // Carry Lookahead Adder for head+1
  wire [2:0] head_plus_1_inv = ~head;
  wire [2:0] carry_gen_plus = head & 3'b001;
  wire [2:0] carry_prop_plus = head ^ 3'b001;
  wire [2:0] carry_plus = {carry_gen_plus[2] | (carry_prop_plus[2] & carry_gen_plus[1]) | 
                          (carry_prop_plus[2] & carry_prop_plus[1] & carry_gen_plus[0]),
                          carry_gen_plus[1] | (carry_prop_plus[1] & carry_gen_plus[0]),
                          carry_gen_plus[0]};
  assign head_plus_1 = (head == PORTS-1) ? 0 : (head ^ 3'b001 ^ carry_plus);
  
  assign next_head = head_plus_1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 0;
      tail <= 0;
      grant <= 0;
      for (integer i = 0; i < PORTS; i = i + 1)
        queue[i] <= 0;
    end else begin
      if (|done) begin
        grant <= 0;
        head <= next_head;
      end
      
      if (head != tail && grant == 0)
        grant <= (1 << queue[head]);
        
      for (integer i = 0; i < PORTS; i = i + 1) begin
        if (req[i] && !(|grant)) begin
          queue[tail] <= i;
          tail <= (tail == PORTS-1) ? 0 : (tail + 1);
        end
      end
    end
  end

endmodule