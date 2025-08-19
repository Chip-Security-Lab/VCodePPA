//SystemVerilog
module glitch_free_divider (
    input wire clk_i, rst_i,
    output wire clk_o
);
    // Counter register with additional bit for toggling
    reg [2:0] count_r;
    reg toggle_r;
    reg clk_out_r;
    
    // Positive edge logic with optimized counter structure
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            count_r <= 3'd0;
            toggle_r <= 1'b0;
        end else begin
            if (count_r == 3'd6) begin
                count_r <= 3'd0;
                toggle_r <= ~toggle_r;
            end else begin
                count_r <= count_r + 3'd1;
            end
        end
    end
    
    // Clock output synchronization to avoid glitches
    always @(negedge clk_i or posedge rst_i) begin
        if (rst_i)
            clk_out_r <= 1'b0;
        else
            clk_out_r <= toggle_r;
    end
    
    // Final output assignment
    assign clk_o = clk_out_r;
endmodule