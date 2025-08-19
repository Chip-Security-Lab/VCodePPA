//SystemVerilog
module dynamic_priority_arbiter(
  input wire clk, 
  input wire rst_n,
  input wire [7:0] requests,
  input wire [23:0] dynamic_priority, // 8 x 3-bit priorities
  output reg [7:0] grants
);

  // Priority extraction stage
  wire [2:0] priority_array [0:7];
  genvar g;
  generate
    for (g = 0; g < 8; g = g + 1) begin: priority_extract
      assign priority_array[g] = dynamic_priority[g*3 +: 3];
    end
  endgenerate

  // Priority comparison stage - optimized for better PPA
  reg [2:0] max_priority;
  reg [7:0] max_priority_mask;
  reg [7:0] valid_requests;
  reg [7:0] higher_priority_mask;
  
  // First stage: Identify valid requests
  always @(*) begin
    valid_requests = requests;
  end
  
  // Second stage: Find maximum priority
  always @(*) begin
    max_priority = 3'b0;
    for (integer i = 0; i < 8; i = i + 1) begin
      if (valid_requests[i] && priority_array[i] > max_priority) begin
        max_priority = priority_array[i];
      end
    end
  end
  
  // Third stage: Create mask for highest priority requests
  always @(*) begin
    max_priority_mask = 8'b0;
    for (integer i = 0; i < 8; i = i + 1) begin
      if (valid_requests[i] && priority_array[i] == max_priority) begin
        max_priority_mask[i] = 1'b1;
      end
    end
  end

  // Grant generation stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grants <= 8'b0;
    end else begin
      grants <= (|requests) ? max_priority_mask : 8'b0;
    end
  end

endmodule