//SystemVerilog
// Top level module
module age_based_arbiter #(parameter CLIENTS = 6) (
  input clk, reset,
  input [CLIENTS-1:0] requests,
  output [CLIENTS-1:0] grants
);

  wire [3:0] age [0:CLIENTS-1];
  wire [CLIENTS-1:0] age_inc;
  wire [CLIENTS-1:0] grant_logic;

  // Age counter module
  age_counter #(.CLIENTS(CLIENTS)) age_counter_inst (
    .clk(clk),
    .reset(reset),
    .requests(requests),
    .grants(grants),
    .age(age),
    .age_inc(age_inc)
  );

  // Priority logic module  
  priority_logic #(.CLIENTS(CLIENTS)) priority_logic_inst (
    .requests(requests),
    .age(age),
    .grants(grant_logic)
  );

  // Grant register module
  grant_register #(.CLIENTS(CLIENTS)) grant_register_inst (
    .clk(clk),
    .reset(reset),
    .grant_in(grant_logic),
    .grants(grants)
  );

endmodule

// Age counter submodule
module age_counter #(parameter CLIENTS = 6) (
  input clk, reset,
  input [CLIENTS-1:0] requests,
  input [CLIENTS-1:0] grants,
  output reg [3:0] age [0:CLIENTS-1],
  output [CLIENTS-1:0] age_inc
);

  // Age increment logic - optimized with direct assignment
  assign age_inc = requests & ~grants;

  // Age counter update logic - optimized with single always block
  always @(posedge clk) begin
    if (reset) begin
      for (int i = 0; i < CLIENTS; i = i + 1)
        age[i] <= 0;
    end else begin
      for (int i = 0; i < CLIENTS; i = i + 1)
        if (age_inc[i])
          age[i] <= age[i] + 1;
    end
  end

endmodule

// Priority logic submodule
module priority_logic #(parameter CLIENTS = 6) (
  input [CLIENTS-1:0] requests,
  input [3:0] age [0:CLIENTS-1],
  output reg [CLIENTS-1:0] grants
);

  // Maximum age calculation - optimized with parallel comparison
  reg [3:0] max_age;
  reg [CLIENTS-1:0] max_age_mask;
  reg [CLIENTS-1:0] valid_requests;
  
  // Pre-compute valid requests to avoid redundant checks
  always @(*) begin
    valid_requests = requests;
    max_age = 0;
    max_age_mask = 0;
    
    // First pass: find maximum age among valid requests
    for (int i = 0; i < CLIENTS; i = i + 1) begin
      if (valid_requests[i] && age[i] > max_age) begin
        max_age = age[i];
      end
    end
    
    // Second pass: create mask for all requests with maximum age
    for (int i = 0; i < CLIENTS; i = i + 1) begin
      if (valid_requests[i] && age[i] == max_age) begin
        max_age_mask[i] = 1'b1;
      end
    end
  end

  // Grant generation - optimized with direct assignment
  always @(*) begin
    grants = max_age_mask & requests;
  end

endmodule

// Grant register submodule
module grant_register #(parameter CLIENTS = 6) (
  input clk, reset,
  input [CLIENTS-1:0] grant_in,
  output reg [CLIENTS-1:0] grants
);

  always @(posedge clk) begin
    if (reset)
      grants <= 0;
    else
      grants <= grant_in;
  end

endmodule