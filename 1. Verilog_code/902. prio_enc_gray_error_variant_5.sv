//SystemVerilog
module prio_enc_gray_error #(
  parameter N = 8
)(
  input      [N-1:0]            req,
  output reg [$clog2(N)-1:0]    gray_out,
  output                         error
);
  
  // Internal pipeline registers
  reg  [N-1:0]            req_processed;
  wire [$clog2(N)-1:0]    bin_encoded;
  wire                     valid_request;
  
  // Stage 1: Request validation and preprocessing
  always @(*) begin
    req_processed = req;
  end
  
  assign valid_request = |req_processed;
  assign error = ~valid_request;
  
  // Stage 2: Binary encoding path
  // Priority encoder implementation with improved structure
  reg [$clog2(N)-1:0] bin_temp;
  integer i;
  
  always @(*) begin
    bin_temp = {$clog2(N){1'b0}}; // Explicit width initialization
    for(i = N-1; i >= 0; i = i-1) begin  // Reverse priority (MSB has priority)
      if(req_processed[i]) begin
        bin_temp = i[$clog2(N)-1:0];
      end
    end
  end
  
  // Intermediate data path with priority resolution
  assign bin_encoded = valid_request ? bin_temp : {$clog2(N){1'b0}};
  
  // Stage 3: Binary to Gray code conversion
  // Dedicated conversion logic
  always @(*) begin
    gray_out = (bin_encoded >> 1) ^ bin_encoded;
  end
  
endmodule