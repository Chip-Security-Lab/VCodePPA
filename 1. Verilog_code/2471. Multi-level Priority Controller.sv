module multi_level_intr_ctrl(
  input clk, reset_n,
  input [15:0] intr_source,
  input [1:0] level_sel,
  output reg [3:0] intr_id,
  output reg active
);
    // Fix: Implement a simple priority encoder instead of using the unspecified module
    function [3:0] find_first_bit;
        input [3:0] vec;
        reg [3:0] result;
        begin
            result = 4'd0;
            if (vec[0]) result = 4'd0;
            else if (vec[1]) result = 4'd1;
            else if (vec[2]) result = 4'd2;
            else if (vec[3]) result = 4'd3;
            find_first_bit = result;
        end
    endfunction
    
    wire [3:0] high_id, med_id, low_id, sys_id;
    wire high_v, med_v, low_v, sys_v;
    
    // Determine if any interrupt is active in each category
    assign high_v = |intr_source[15:12];
    assign med_v = |intr_source[11:8];
    assign low_v = |intr_source[7:4];
    assign sys_v = |intr_source[3:0];
    
    // Find highest priority within each category
    assign high_id = find_first_bit(intr_source[15:12]);
    assign med_id = find_first_bit(intr_source[11:8]);
    assign low_id = find_first_bit(intr_source[7:4]);
    assign sys_id = find_first_bit(intr_source[3:0]);
  
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            intr_id <= 4'd0;
            active <= 1'b0;
        end else begin
            active <= high_v | med_v | low_v | sys_v;
            
            case (level_sel)
                2'b00: begin
                    if (high_v) intr_id <= {2'b11, high_id};
                    else if (med_v) intr_id <= {2'b10, med_id};
                    else if (low_v) intr_id <= {2'b01, low_id};
                    else intr_id <= {2'b00, sys_id};
                end
                2'b01: begin
                    if (med_v) intr_id <= {2'b10, med_id};
                    else if (low_v) intr_id <= {2'b01, low_id};
                    else if (sys_v) intr_id <= {2'b00, sys_id};
                    else intr_id <= {2'b11, high_id};
                end
                2'b10: begin
                    if (low_v) intr_id <= {2'b01, low_id};
                    else if (sys_v) intr_id <= {2'b00, sys_id};
                    else if (high_v) intr_id <= {2'b11, high_id};
                    else intr_id <= {2'b10, med_id};
                end
                2'b11: begin
                    if (sys_v) intr_id <= {2'b00, sys_id};
                    else if (high_v) intr_id <= {2'b11, high_id};
                    else if (med_v) intr_id <= {2'b10, med_id};
                    else intr_id <= {2'b01, low_id};
                end
                default: intr_id <= 4'd0;
            endcase
        end
    end
endmodule