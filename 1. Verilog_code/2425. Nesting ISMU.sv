module nesting_ismu(
    input clk, rst,
    input [7:0] intr_src,
    input [7:0] intr_enable,
    input [7:0] intr_priority,
    input [2:0] current_level,
    output reg [2:0] intr_level,
    output reg intr_active
);
    wire [7:0] active_src;
    wire [2:0] max_level;
    
    assign active_src = intr_src & intr_enable;
    assign max_level = (active_src[7] & intr_priority[7] > current_level) ? 3'd7 :
                       (active_src[6] & intr_priority[6] > current_level) ? 3'd6 :
                       (active_src[5] & intr_priority[5] > current_level) ? 3'd5 :
                       (active_src[4] & intr_priority[4] > current_level) ? 3'd4 :
                       (active_src[3] & intr_priority[3] > current_level) ? 3'd3 :
                       (active_src[2] & intr_priority[2] > current_level) ? 3'd2 :
                       (active_src[1] & intr_priority[1] > current_level) ? 3'd1 :
                       (active_src[0] & intr_priority[0] > current_level) ? 3'd0 : 3'd0;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_level <= 3'd0;
            intr_active <= 1'b0;
        end else begin
            intr_active <= |active_src && (max_level > current_level);
            intr_level <= max_level;
        end
    end
endmodule