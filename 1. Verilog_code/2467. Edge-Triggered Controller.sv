module edge_triggered_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_in,
  output reg [2:0] intr_num,
  output reg intr_pending
);
    reg [7:0] intr_prev;
    wire [7:0] intr_edge;
    reg [7:0] intr_flag;
  
    assign intr_edge = intr_in & ~intr_prev;
  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_prev <= 8'h0;
            intr_flag <= 8'h0;
            intr_num <= 3'h0;
            intr_pending <= 1'b0;
        end else begin
            intr_prev <= intr_in;
            intr_flag <= (intr_flag | intr_edge);
            intr_pending <= |intr_flag;
      
            if (|intr_flag) begin
                casez (intr_flag)
                    8'b???????1: intr_num <= 3'd0;
                    8'b??????10: intr_num <= 3'd1;
                    8'b?????100: intr_num <= 3'd2;
                    8'b????1000: intr_num <= 3'd3;
                    8'b???10000: intr_num <= 3'd4;
                    8'b??100000: intr_num <= 3'd5;
                    8'b?1000000: intr_num <= 3'd6;
                    8'b10000000: intr_num <= 3'd7;
                    default: intr_num <= intr_num; // No change
                endcase
            end
        end
    end
endmodule