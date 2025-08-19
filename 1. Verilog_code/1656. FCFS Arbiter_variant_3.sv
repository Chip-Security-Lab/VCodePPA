//SystemVerilog
module fcfs_arbiter #(parameter PORTS = 4) (
  input wire clk,
  input wire rst_n,
  input wire [PORTS-1:0] req,
  input wire [PORTS-1:0] done,
  output reg [PORTS-1:0] grant
);

  // Queue storage and pointers
  reg [PORTS-1:0] queue [0:PORTS-1];
  reg [2:0] head_ptr;
  reg [2:0] tail_ptr;
  
  // Pipeline registers
  reg [PORTS-1:0] req_reg;
  reg [PORTS-1:0] done_reg;
  reg [PORTS-1:0] grant_next;
  
  // Queue management logic
  wire queue_full;
  wire queue_empty;
  wire [PORTS-1:0] valid_req;
  
  // Carry-skip adder signals for pointer operations
  wire [2:0] head_ptr_next;
  wire [2:0] tail_ptr_next;
  wire head_carry_out;
  wire tail_carry_out;
  
  // Queue status signals
  assign queue_full = (tail_ptr_next == head_ptr);
  assign queue_empty = (head_ptr == tail_ptr);
  assign valid_req = req & ~grant;
  
  // Carry-skip adder for head pointer increment
  carry_skip_adder_3bit head_ptr_adder (
    .a(head_ptr),
    .b(3'b001),
    .cin(1'b0),
    .sum(head_ptr_next),
    .cout(head_carry_out)
  );
  
  // Carry-skip adder for tail pointer increment
  carry_skip_adder_3bit tail_ptr_adder (
    .a(tail_ptr),
    .b(3'b001),
    .cin(1'b0),
    .sum(tail_ptr_next),
    .cout(tail_carry_out)
  );
  
  // Request registration stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_reg <= 0;
      done_reg <= 0;
    end else begin
      req_reg <= req;
      done_reg <= done;
    end
  end
  
  // Queue update stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head_ptr <= 0;
      tail_ptr <= 0;
      for (integer i = 0; i < PORTS; i = i + 1)
        queue[i] <= 0;
    end else begin
      // Enqueue new requests
      if (|valid_req && !queue_full) begin
        for (integer i = 0; i < PORTS; i = i + 1) begin
          if (valid_req[i]) begin
            queue[tail_ptr] <= i;
            tail_ptr <= tail_ptr_next;
          end
        end
      end
      
      // Dequeue completed requests
      if (|done_reg && !queue_empty) begin
        head_ptr <= head_ptr_next;
      end
    end
  end
  
  // Grant generation stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 0;
      grant_next <= 0;
    end else begin
      grant <= grant_next;
      
      if (|done_reg) begin
        grant_next <= 0;
      end else if (!queue_empty && grant == 0) begin
        grant_next <= (1 << queue[head_ptr]);
      end
    end
  end

endmodule

// 3-bit carry-skip adder module
module carry_skip_adder_3bit (
  input wire [2:0] a,
  input wire [2:0] b,
  input wire cin,
  output wire [2:0] sum,
  output wire cout
);
  
  // Group signals
  wire [2:0] p, g;
  wire [2:0] carry;
  
  // Generate and propagate signals
  assign p = a ^ b;
  assign g = a & b;
  
  // First carry
  assign carry[0] = g[0] | (p[0] & cin);
  
  // Middle carry with skip logic
  wire skip_condition = p[1] & p[0];
  assign carry[1] = g[1] | (p[1] & carry[0]);
  
  // Final carry
  assign carry[2] = g[2] | (p[2] & carry[1]);
  
  // Sum calculation
  assign sum[0] = p[0] ^ cin;
  assign sum[1] = p[1] ^ carry[0];
  assign sum[2] = p[2] ^ carry[1];
  
  // Output carry
  assign cout = carry[2];
  
endmodule