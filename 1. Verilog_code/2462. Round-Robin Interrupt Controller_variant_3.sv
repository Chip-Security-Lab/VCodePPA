//SystemVerilog
// SystemVerilog
module round_robin_intr_ctrl #(parameter WIDTH=4)(
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] grant,
  output reg active
);
  // Stage 1 registers - Request capture & double request generation
  reg [WIDTH-1:0] req_stage1;
  reg [WIDTH-1:0] pointer_stage1;
  reg valid_stage1;
  reg reset_stage1;
  
  // Stage 2 registers - Priority calculation 
  reg [2*WIDTH-1:0] double_req_stage2;
  reg [WIDTH-1:0] pointer_stage2;
  reg valid_stage2;
  reg reset_stage2;
  
  // Stage 3 registers - Grant generation
  reg [2*WIDTH-1:0] double_grant_stage3;
  reg [WIDTH-1:0] pointer_stage3;
  reg valid_stage3;
  reg reset_stage3;
  
  // Intermediate signals for calculation
  wire [2*WIDTH-1:0] double_grant_calc;
  
  //----------------------------------------------------------------------
  // Pipeline Stage 1: Request capture
  //----------------------------------------------------------------------
  // Reset handling for stage 1
  always @(posedge clock) begin
    if (reset) begin
      reset_stage1 <= 1'b1;
      valid_stage1 <= 1'b0;
    end else begin
      reset_stage1 <= 1'b0;
      valid_stage1 <= 1'b1;
    end
  end
  
  // Request capture
  always @(posedge clock) begin
    if (reset) begin
      req_stage1 <= {WIDTH{1'b0}};
    end else begin
      req_stage1 <= req;
    end
  end
  
  // Pointer handling for stage 1
  always @(posedge clock) begin
    if (reset) begin
      pointer_stage1 <= {{(WIDTH-1){1'b0}}, 1'b1};
    end else begin
      pointer_stage1 <= grant[WIDTH-1:0] ? {grant[WIDTH-2:0], grant[WIDTH-1]} : pointer_stage1;
    end
  end
  
  //----------------------------------------------------------------------
  // Pipeline Stage 2: Priority calculation
  //----------------------------------------------------------------------
  // Reset and valid signal handling for stage 2
  always @(posedge clock) begin
    if (reset) begin
      reset_stage2 <= 1'b1;
      valid_stage2 <= 1'b0;
    end else begin
      reset_stage2 <= reset_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Double request generation for circular priority
  always @(posedge clock) begin
    if (reset) begin
      double_req_stage2 <= {2*WIDTH{1'b0}};
    end else begin
      double_req_stage2 <= {req_stage1, req_stage1};
    end
  end
  
  // Pointer forwarding from stage 1 to stage 2
  always @(posedge clock) begin
    if (reset) begin
      pointer_stage2 <= {{(WIDTH-1){1'b0}}, 1'b1};
    end else begin
      pointer_stage2 <= pointer_stage1;
    end
  end
  
  //----------------------------------------------------------------------
  // Pipeline Stage 3: Grant generation
  //----------------------------------------------------------------------
  // Reset and valid signal handling for stage 3
  always @(posedge clock) begin
    if (reset) begin
      reset_stage3 <= 1'b1;
      valid_stage3 <= 1'b0;
    end else begin
      reset_stage3 <= reset_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Priority mask calculation
  assign double_grant_calc = double_req_stage2 & 
                           ~((double_req_stage2 - {{(WIDTH){1'b0}}, pointer_stage2}) | 
                            {{(WIDTH){1'b0}}, pointer_stage2});
  
  // Double grant register update
  always @(posedge clock) begin
    if (reset) begin
      double_grant_stage3 <= {2*WIDTH{1'b0}};
    end else begin
      double_grant_stage3 <= double_grant_calc;
    end
  end
  
  // Pointer forwarding from stage 2 to stage 3
  always @(posedge clock) begin
    if (reset) begin
      pointer_stage3 <= {{(WIDTH-1){1'b0}}, 1'b1};
    end else begin
      pointer_stage3 <= pointer_stage2;
    end
  end
  
  //----------------------------------------------------------------------
  // Output stage: Final grant and active signal generation
  //----------------------------------------------------------------------
  // Active signal generation
  always @(posedge clock) begin
    if (reset) begin
      active <= 1'b0;
    end else if (valid_stage3 && !reset_stage3) begin
      active <= |double_grant_stage3;
    end
  end
  
  // Grant signal generation
  always @(posedge clock) begin
    if (reset) begin
      grant <= {WIDTH{1'b0}};
    end else if (valid_stage3 && !reset_stage3) begin
      if (|double_grant_stage3) begin
        grant <= double_grant_stage3[WIDTH-1:0] | double_grant_stage3[2*WIDTH-1:WIDTH];
      end
    end else if (reset_stage3) begin
      grant <= {WIDTH{1'b0}};
    end
  end
  
endmodule