//SystemVerilog
module scalable_intr_ctrl #(
  parameter SOURCES = 32,
  parameter ID_WIDTH = $clog2(SOURCES)
)(
  input wire clk, rst,
  input wire [SOURCES-1:0] requests,
  output reg [ID_WIDTH-1:0] grant_id,
  output reg grant_valid
);

  // Stage 1: Request detection and initial processing
  reg requests_valid_stage1;
  reg [SOURCES-1:0] requests_stage1;
  
  // Stage 2: Priority encoding
  reg [ID_WIDTH-1:0] grant_id_stage2;
  reg requests_valid_stage2;
  
  // Stage 1: Capture and buffer input requests
  always @(posedge clk) begin
    if (rst) begin
      requests_stage1 <= {SOURCES{1'b0}};
      requests_valid_stage1 <= 1'b0;
    end else begin
      requests_stage1 <= requests;
      requests_valid_stage1 <= |requests;
    end
  end
  
  // Stage 2: Priority encoding logic - split into two parts
  // Part 1: Upper half of sources
  reg [ID_WIDTH-1:0] upper_id;
  reg upper_valid;
  
  integer i;
  always @(posedge clk) begin
    if (rst) begin
      upper_id <= {ID_WIDTH{1'b0}};
      upper_valid <= 1'b0;
    end else begin
      upper_id <= {ID_WIDTH{1'b0}};
      upper_valid <= 1'b0;
      
      for (i = SOURCES-1; i >= SOURCES/2; i = i - 1) begin
        if (requests_stage1[i]) begin
          upper_id <= i[ID_WIDTH-1:0];
          upper_valid <= 1'b1;
        end
      end
    end
  end
  
  // Part 2: Lower half of sources
  reg [ID_WIDTH-1:0] lower_id;
  reg lower_valid;
  
  integer j;
  always @(posedge clk) begin
    if (rst) begin
      lower_id <= {ID_WIDTH{1'b0}};
      lower_valid <= 1'b0;
    end else begin
      lower_id <= {ID_WIDTH{1'b0}};
      lower_valid <= 1'b0;
      
      for (j = (SOURCES/2)-1; j >= 0; j = j - 1) begin
        if (requests_stage1[j]) begin
          lower_id <= j[ID_WIDTH-1:0];
          lower_valid <= 1'b1;
        end
      end
    end
  end
  
  // Stage 3: Merge results and generate final grant
  always @(posedge clk) begin
    if (rst) begin
      grant_id <= {ID_WIDTH{1'b0}};
      grant_valid <= 1'b0;
      requests_valid_stage2 <= 1'b0;
      grant_id_stage2 <= {ID_WIDTH{1'b0}};
    end else begin
      // Pipeline stage 2 to 3 transition
      requests_valid_stage2 <= requests_valid_stage1;
      
      // Priority selection logic (upper half has higher priority)
      if (upper_valid) begin
        grant_id_stage2 <= upper_id;
      end else if (lower_valid) begin
        grant_id_stage2 <= lower_id;
      end else begin
        grant_id_stage2 <= {ID_WIDTH{1'b0}};
      end
      
      // Final output stage
      grant_valid <= requests_valid_stage2;
      grant_id <= grant_id_stage2;
    end
  end
  
endmodule