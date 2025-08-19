//SystemVerilog
//-----------------------------------------------------------------------------
// Project: Matrix Arbiter System
// Module:  Top Level Arbiter Module
// Author:  
// Description: Hierarchical implementation of a matrix arbiter with 
//              configurable number of clients
//-----------------------------------------------------------------------------

module matrix_arbiter #(
  parameter CLIENTS = 3
)(
  input  wire                clk,
  input  wire [CLIENTS-1:0]  req_i,
  output wire [CLIENTS-1:0]  gnt_o
);

  // Internal signals
  wire [CLIENTS-1:0] priority_matrix [CLIENTS-1:0];
  wire [CLIENTS-1:0] masked_requests;

  // Priority matrix generator instance
  priority_matrix_generator #(
    .CLIENTS(CLIENTS)
  ) priority_gen_inst (
    .priority_matrix(priority_matrix)
  );

  // Request masking and grant generation instance
  grant_generator #(
    .CLIENTS(CLIENTS)
  ) grant_gen_inst (
    .req_i(req_i),
    .priority_matrix(priority_matrix),
    .gnt_o(gnt_o)
  );

endmodule

//-----------------------------------------------------------------------------
// Module:  Priority Matrix Generator
// Description: Generates the priority matrix for arbiter based on client indices
//-----------------------------------------------------------------------------

module priority_matrix_generator #(
  parameter CLIENTS = 3
)(
  output reg [CLIENTS-1:0] priority_matrix [CLIENTS-1:0]
);

  integer i, j;
  
  // Initialize priority matrix to zeros
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1) 
      priority_matrix[i] = {CLIENTS{1'b0}};
  end
  
  // Set priority flags where i > j (higher index has priority over lower)
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1)
      for (j = 0; j < CLIENTS; j = j + 1)
        if (i > j) priority_matrix[i][j] = 1'b1;
  end

endmodule

//-----------------------------------------------------------------------------
// Module:  Grant Generator
// Description: Determines which clients receive grants based on requests and
//              priority matrix
//-----------------------------------------------------------------------------

module grant_generator #(
  parameter CLIENTS = 3
)(
  input  wire [CLIENTS-1:0] req_i,
  input  wire [CLIENTS-1:0] priority_matrix [CLIENTS-1:0],
  output reg  [CLIENTS-1:0] gnt_o
);

  integer i;
  reg [CLIENTS-1:0] priority_conflicts [CLIENTS-1:0];
  
  // Calculate priority conflicts for each client
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1) begin
      priority_conflicts[i] = req_i & priority_matrix[i];
    end
  end
  
  // Generate grant signals based on requests and priority conflicts
  always @(*) begin
    gnt_o = {CLIENTS{1'b0}};
  end
  
  // Process each client's grant independently
  always @(*) begin
    for (i = 0; i < CLIENTS; i = i + 1) begin
      // Client i gets a grant if it has a request AND no higher priority
      // client also has a request (no priority conflicts)
      gnt_o[i] = req_i[i] & ~|priority_conflicts[i];
    end
  end

endmodule