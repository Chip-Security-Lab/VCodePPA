//SystemVerilog
module reset_chain_monitor (
  input wire clk,
  input wire rst_n,
  input wire [3:0] reset_chain,
  output reg reset_chain_error
);

  // Pipeline stage 1 - Sample and check input
  reg [3:0] reset_chain_stage1;
  reg reset_chain_valid_stage1;
  
  // Pipeline stage 2 - Process and generate error
  reg reset_chain_error_stage2;
  reg reset_chain_valid_stage2;
  
  // Stage 1: Sample input and perform initial check
  always @(posedge clk) begin
    case (rst_n)
      1'b0: begin
        reset_chain_stage1 <= 4'b0000;
        reset_chain_valid_stage1 <= 1'b0;
      end
      1'b1: begin
        reset_chain_stage1 <= reset_chain;
        reset_chain_valid_stage1 <= 1'b1;
      end
    endcase
  end
  
  // Stage 2: Detect error condition
  always @(posedge clk) begin
    case (rst_n)
      1'b0: begin
        reset_chain_error_stage2 <= 1'b0;
        reset_chain_valid_stage2 <= 1'b0;
      end
      1'b1: begin
        reset_chain_valid_stage2 <= reset_chain_valid_stage1;
        if (reset_chain_valid_stage1) begin
          case (reset_chain_stage1)
            4'b0000,
            4'b1111: reset_chain_error_stage2 <= 1'b0;
            default: reset_chain_error_stage2 <= 1'b1;
          endcase
        end
      end
    endcase
  end
  
  // Final output stage
  always @(posedge clk) begin
    case ({rst_n, reset_chain_valid_stage2})
      2'b00,
      2'b01: begin
        reset_chain_error <= 1'b0;
      end
      2'b11: begin
        reset_chain_error <= reset_chain_error_stage2;
      end
      default: begin
        // Keep previous value
      end
    endcase
  end

endmodule