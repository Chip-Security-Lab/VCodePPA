//SystemVerilog
module fsm_arbiter(
  input wire clock,
  input wire resetn,
  input wire [3:0] request,
  output reg [3:0] grant
);

  // State definitions
  localparam IDLE  = 2'b00;
  localparam GRANT0 = 2'b01;
  localparam GRANT1 = 2'b10;
  localparam GRANT2 = 2'b11;
  
  // State registers
  reg [1:0] current_state;
  reg [1:0] next_state;
  
  // Request processing pipeline
  reg [3:0] request_sync;
  reg [3:0] grant_comb;
  
  // State transition pipeline
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // Request synchronization
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      request_sync <= 4'b0;
    end else begin
      request_sync <= request;
    end
  end
  
  // Grant output pipeline
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      grant <= 4'b0;
    end else begin
      grant <= grant_comb;
    end
  end
  
  // Next state logic
  always @(*) begin
    next_state = current_state;
    
    case (current_state)
      IDLE: begin
        if (|request_sync) begin
          next_state = GRANT0;
        end
      end
      
      GRANT0: begin
        if (!request_sync[0]) begin
          next_state = GRANT1;
        end
      end
      
      GRANT1: begin
        if (!request_sync[1]) begin
          next_state = GRANT2;
        end
      end
      
      GRANT2: begin
        if (!request_sync[2]) begin
          next_state = IDLE;
        end
      end
      
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  // Grant generation logic
  always @(*) begin
    grant_comb = 4'b0;
    
    case (current_state)
      GRANT0: begin
        grant_comb = 4'b0001 & {4{request_sync[0]}};
      end
      
      GRANT1: begin
        grant_comb = 4'b0010 & {4{request_sync[1]}};
      end
      
      GRANT2: begin
        grant_comb = 4'b0100 & {4{request_sync[2]}};
      end
      
      default: begin
        grant_comb = 4'b0;
      end
    endcase
  end

endmodule