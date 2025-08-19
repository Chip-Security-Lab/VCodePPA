module nested_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_req,
  input [7:0] intr_mask,
  input [15:0] intr_priority, // 2 bits per interrupt
  input ack,
  output reg [2:0] intr_id,
  output reg intr_valid
);
    reg [1:0] current_level;
    reg [7:0] pending;
    integer i;
  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 8'h0;
            current_level <= 2'b11; 
            intr_id <= 3'b0;
            intr_valid <= 1'b0;
        end else begin
            pending <= pending | (intr_req & intr_mask);
            if (ack) pending[intr_id] <= 1'b0;
      
            intr_valid <= 1'b0;
            current_level <= 2'b11; // Default to lowest priority
            
            // Priority encoding - highest priority first
            for (i = 0; i < 8; i = i + 1) begin
                if (pending[i] && intr_priority[i*2+:2] < current_level) begin
                    intr_id <= i[2:0];
                    current_level <= intr_priority[i*2+:2];
                    intr_valid <= 1'b1;
                end
            end
        end
    end
endmodule