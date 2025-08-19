//SystemVerilog
// IEEE 1364-2005 Verilog standard
module prio_enc_onehot #(parameter W=5)(
  input [W-1:0] req_onehot,
  output [W-1:0] enc_out
);
  // Internal signals
  wire has_valid_req;
  wire [W-1:0] valid_position;
  
  // Check if there's any valid request
  request_detector #(.WIDTH(W)) u_req_detect (
    .req_vector(req_onehot),
    .has_request(has_valid_req)
  );
  
  // Find position of valid request
  position_encoder #(.WIDTH(W)) u_pos_enc (
    .req_vector(req_onehot),
    .position(valid_position)
  );
  
  // Generate one-hot output based on detected position
  output_generator #(.WIDTH(W)) u_out_gen (
    .has_request(has_valid_req),
    .position(valid_position),
    .encoded_output(enc_out)
  );
  
endmodule

// Module to detect if there's any valid request
module request_detector #(parameter WIDTH=5)(
  input [WIDTH-1:0] req_vector,
  output has_request
);
  assign has_request = |req_vector;
endmodule

// Module to encode the position of valid request
module position_encoder #(parameter WIDTH=5)(
  input [WIDTH-1:0] req_vector,
  output [WIDTH-1:0] position
);
  integer i;
  reg [WIDTH-1:0] pos;
  
  always @(*) begin
    pos = {WIDTH{1'b0}};
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (req_vector[i]) begin
        pos = i;
      end
    end
  end
  
  assign position = pos;
endmodule

// Module to generate the one-hot encoded output
module output_generator #(parameter WIDTH=5)(
  input has_request,
  input [WIDTH-1:0] position,
  output [WIDTH-1:0] encoded_output
);
  assign encoded_output = has_request ? (1'b1 << position) : {WIDTH{1'b0}};
endmodule