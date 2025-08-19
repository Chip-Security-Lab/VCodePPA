module sequential_reset_controller (
  input wire clk,
  input wire rst_trigger,
  output reg [3:0] rst_vector
);
  localparam IDLE = 2'b00, RESET = 2'b01, RELEASE = 2'b10;
  reg [1:0] state;
  reg [2:0] step;
  
  always @(posedge clk) begin
    case (state)
      IDLE: if (rst_trigger) begin
              state <= RESET;
              step <= 3'd0;
              rst_vector <= 4'b1111;
            end
      RESET: if (step < 3'd4) begin
               step <= step + 3'd1;
             end else begin
               state <= RELEASE;
               step <= 3'd0;
             end
      RELEASE: begin
        if (step < 3'd4) begin
          rst_vector[step] <= 1'b0;
          step <= step + 3'd1;
        end else state <= IDLE;
      end
    endcase
  end
endmodule