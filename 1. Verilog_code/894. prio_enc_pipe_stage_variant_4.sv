//SystemVerilog
// IEEE 1364-2005
// Manchester carry chain module for priority encoding
module manchester_carry_chain #(parameter W=32)(
  input [W-1:0] req_in,
  output [W-1:0] priority_mask,
  output [W-1:0] priority_out
);
  // Generate priority mask
  assign priority_mask[0] = req_in[0];
  
  genvar i;
  generate
    for(i=1; i<W; i=i+1) begin: gen_mask
      assign priority_mask[i] = priority_mask[i-1] | req_in[i];
    end
  endgenerate
  
  // Generate priority output - only highest priority bit will be set
  assign priority_out[0] = req_in[0];
  
  generate
    for(i=1; i<W; i=i+1) begin: gen_priority
      assign priority_out[i] = req_in[i] & ~priority_mask[i-1];
    end
  endgenerate
endmodule

// Priority encoder module
module priority_encoder #(parameter W=32, A=5)(
  input [W-1:0] priority_out,
  output reg [A-1:0] addr
);
  always @(*) begin
    addr = {A{1'b0}};
    for(integer j=0; j<W; j=j+1)
      if(priority_out[j]) addr = j[A-1:0];
  end
endmodule

// Register module
module priority_registers #(parameter W=32, A=5)(
  input clk, rst,
  input [W-1:0] req_in,
  input [A-1:0] addr_in,
  output reg [W-1:0] req_pipe,
  output reg [A-1:0] addr_reg
);
  always @(posedge clk) begin
    if (rst) begin
      req_pipe <= {W{1'b0}};
      addr_reg <= {A{1'b0}};
    end
    else begin
      req_pipe <= req_in;
      addr_reg <= addr_in;
    end
  end
endmodule

// Top-level priority encoder with pipelining
module prio_enc_pipe_stage #(parameter W=32, A=5)(
  input clk, rst,
  input [W-1:0] req,
  output [A-1:0] addr_reg
);
  // Internal signals
  wire [W-1:0] req_pipe;
  wire [W-1:0] priority_mask;
  wire [W-1:0] priority_out;
  wire [A-1:0] addr_next;
  
  // Instance of Manchester carry chain
  manchester_carry_chain #(.W(W)) manchester_chain (
    .req_in(req_pipe),
    .priority_mask(priority_mask),
    .priority_out(priority_out)
  );
  
  // Instance of priority encoder
  priority_encoder #(.W(W), .A(A)) encoder (
    .priority_out(priority_out),
    .addr(addr_next)
  );
  
  // Instance of registers
  priority_registers #(.W(W), .A(A)) regs (
    .clk(clk),
    .rst(rst),
    .req_in(req),
    .addr_in(addr_next),
    .req_pipe(req_pipe),
    .addr_reg(addr_reg)
  );
endmodule