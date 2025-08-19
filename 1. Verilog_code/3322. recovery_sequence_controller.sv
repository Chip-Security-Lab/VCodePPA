module recovery_sequence_controller(
  input clk, rst_n,
  input trigger_recovery,
  output reg [3:0] recovery_stage,
  output reg recovery_in_progress,
  output reg system_reset, module_reset, memory_clear
);
  localparam IDLE = 0, RESET = 1, MODULE_RST = 2, MEM_CLEAR = 3, WAIT = 4;
  reg [2:0] state = IDLE;
  reg [7:0] counter = 8'h00;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      counter <= 8'h00;
      recovery_stage <= 4'h0;
      recovery_in_progress <= 1'b0;
      system_reset <= 1'b0;
      module_reset <= 1'b0;
      memory_clear <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (trigger_recovery) begin
            state <= RESET;
            recovery_in_progress <= 1'b1;
            recovery_stage <= 4'h1;
          end
        end
        RESET: begin
          system_reset <= 1'b1;
          counter <= counter + 1;
          if (counter == 8'hFF) begin
            state <= MODULE_RST;
            counter <= 8'h00;
            system_reset <= 1'b0;
            recovery_stage <= 4'h2;
          end
        end
        MODULE_RST: begin
          module_reset <= 1'b1;
          counter <= counter + 1;
          if (counter == 8'h7F) begin
            state <= MEM_CLEAR;
            counter <= 8'h00;
            module_reset <= 1'b0;
            recovery_stage <= 4'h3;
          end
        end
        MEM_CLEAR: begin
          memory_clear <= 1'b1;
          counter <= counter + 1;
          if (counter == 8'h3F) begin
            state <= WAIT;
            counter <= 8'h00;
            memory_clear <= 1'b0;
            recovery_stage <= 4'h4;
          end
        end
        WAIT: begin
          counter <= counter + 1;
          if (counter == 8'hFF) begin
            state <= IDLE;
            recovery_in_progress <= 1'b0;
            recovery_stage <= 4'h0;
          end
        end
      endcase
    end
  end
endmodule