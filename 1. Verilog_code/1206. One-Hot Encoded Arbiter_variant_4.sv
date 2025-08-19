//SystemVerilog
module one_hot_arbiter(
  input wire clock, clear,
  input wire enable,
  input wire [7:0] requests,
  output reg [7:0] grants
);
  reg [7:0] priority_mask;
  wire [7:0] masked_requests;
  
  // Calculate masked requests directly
  assign masked_requests = requests & ~priority_mask;
  
  // Use priority encoders for more efficient implementation
  reg [3:0] lower_priority_enc;
  reg [3:0] upper_priority_enc;
  reg lower_valid, upper_valid;
  reg [3:0] lower_priority_enc_raw;
  reg [3:0] upper_priority_enc_raw;
  reg lower_valid_raw, upper_valid_raw;
  
  // Registered next grants
  reg [7:0] next_grants;
  
  // More efficient priority encoding for lower bits
  always @(*) begin
    // Default values
    lower_priority_enc_raw = 4'h0;
    lower_valid_raw = 1'b0;
    
    // First try masked requests
    if (masked_requests[0]) begin
      lower_priority_enc_raw = 4'd0;
      lower_valid_raw = 1'b1;
    end else if (masked_requests[1]) begin
      lower_priority_enc_raw = 4'd1;
      lower_valid_raw = 1'b1;
    end else if (masked_requests[2]) begin
      lower_priority_enc_raw = 4'd2;
      lower_valid_raw = 1'b1;
    end else if (masked_requests[3]) begin
      lower_priority_enc_raw = 4'd3;
      lower_valid_raw = 1'b1;
    end
    // Then try raw requests if no masked requests
    else if (requests[0]) begin
      lower_priority_enc_raw = 4'd0;
      lower_valid_raw = 1'b1;
    end else if (requests[1]) begin
      lower_priority_enc_raw = 4'd1;
      lower_valid_raw = 1'b1;
    end else if (requests[2]) begin
      lower_priority_enc_raw = 4'd2;
      lower_valid_raw = 1'b1;
    end else if (requests[3]) begin
      lower_priority_enc_raw = 4'd3;
      lower_valid_raw = 1'b1;
    end
  end
  
  // More efficient priority encoding for upper bits
  always @(*) begin
    // Default values
    upper_priority_enc_raw = 4'h0;
    upper_valid_raw = 1'b0;
    
    // First try masked requests
    if (masked_requests[4]) begin
      upper_priority_enc_raw = 4'd0;
      upper_valid_raw = 1'b1;
    end else if (masked_requests[5]) begin
      upper_priority_enc_raw = 4'd1;
      upper_valid_raw = 1'b1;
    end else if (masked_requests[6]) begin
      upper_priority_enc_raw = 4'd2;
      upper_valid_raw = 1'b1;
    end else if (masked_requests[7]) begin
      upper_priority_enc_raw = 4'd3;
      upper_valid_raw = 1'b1;
    end
    // Then try raw requests if no masked requests
    else if (requests[4]) begin
      upper_priority_enc_raw = 4'd0;
      upper_valid_raw = 1'b1;
    end else if (requests[5]) begin
      upper_priority_enc_raw = 4'd1;
      upper_valid_raw = 1'b1;
    end else if (requests[6]) begin
      upper_priority_enc_raw = 4'd2;
      upper_valid_raw = 1'b1;
    end else if (requests[7]) begin
      upper_priority_enc_raw = 4'd3;
      upper_valid_raw = 1'b1;
    end
  end
  
  // Calculate next grants based on priority encoding
  always @(*) begin
    next_grants = 8'h00;
    
    if (lower_valid) begin
      case (lower_priority_enc)
        4'd0: next_grants = 8'h01;
        4'd1: next_grants = 8'h02;
        4'd2: next_grants = 8'h04;
        4'd3: next_grants = 8'h08;
        default: next_grants = 8'h00;
      endcase
    end else if (upper_valid) begin
      case (upper_priority_enc)
        4'd0: next_grants = 8'h10;
        4'd1: next_grants = 8'h20;
        4'd2: next_grants = 8'h40;
        4'd3: next_grants = 8'h80;
        default: next_grants = 8'h00;
      endcase
    end
  end
  
  // Sequential logic for updating state
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      grants <= 8'h00;
      priority_mask <= 8'h01;
      lower_priority_enc <= 4'h0;
      upper_priority_enc <= 4'h0;
      lower_valid <= 1'b0;
      upper_valid <= 1'b0;
    end
    else if (enable) begin
      // Register priority encoder outputs to reduce combinational path length
      lower_priority_enc <= lower_priority_enc_raw;
      upper_priority_enc <= upper_priority_enc_raw;
      lower_valid <= lower_valid_raw;
      upper_valid <= upper_valid_raw;
      
      // Update grants
      grants <= next_grants;
      
      // Update priority mask based on grants
      if (|next_grants) begin
        priority_mask <= {next_grants[6:0], next_grants[7]};
      end
    end
  end
endmodule