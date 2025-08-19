module phase_locked_clk(
    input ref_clk,
    input target_clk,
    input rst,
    output reg clk_out,
    output reg locked
);
    reg [1:0] phase_state;
    reg ref_detect, target_detect;
    
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            ref_detect <= 1'b0;
            phase_state <= 2'b00;
            locked <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            ref_detect <= 1'b1;
            
            if (target_detect) begin
                phase_state <= 2'b00;
                locked <= 1'b1;
            end else begin
                phase_state <= phase_state + 1;
                locked <= (phase_state == 2'b00);
            end
            
            if (phase_state == 2'b00)
                clk_out <= ~clk_out;
        end
    end
    
    always @(posedge target_clk or posedge rst)
        if (rst) target_detect <= 1'b0;
        else target_detect <= ref_detect;
endmodule