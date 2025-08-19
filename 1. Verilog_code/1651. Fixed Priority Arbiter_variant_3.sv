//SystemVerilog
module fixed_priority_arbiter #(parameter REQ_WIDTH = 4) (
  input wire clk, rst_n,
  input wire [REQ_WIDTH-1:0] request,
  output reg [REQ_WIDTH-1:0] grant
);
  integer i;
  reg [REQ_WIDTH-1:0] request_reg;
  reg [REQ_WIDTH-1:0] grant_next;
  reg [REQ_WIDTH-1:0] grant_buffer;
  
  // First stage: Register input requests to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      request_reg <= {REQ_WIDTH{1'b0}};
    else 
      request_reg <= request;
  end
  
  // Second stage: Calculate next grant state
  always @(*) begin
    grant_next = {REQ_WIDTH{1'b0}};
    for (i = 0; i < REQ_WIDTH; i = i + 1) begin
      if (request_reg[i] && (grant_buffer == {REQ_WIDTH{1'b0}})) 
        grant_next[i] = 1'b1;
    end
  end
  
  // Third stage: Buffer register to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      grant_buffer <= {REQ_WIDTH{1'b0}};
    else 
      grant_buffer <= grant_next;
  end
  
  // Fourth stage: Output register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      grant <= {REQ_WIDTH{1'b0}};
    else 
      grant <= grant_buffer;
  end
endmodule