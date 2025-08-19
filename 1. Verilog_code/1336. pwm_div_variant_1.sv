//SystemVerilog
module pwm_div #(parameter HIGH=3, LOW=5) (
    input  wire clk,
    input  wire rst_n,
    output reg  out
);
    // Pipeline stage 1 - Counter logic
    reg [7:0] cnt_stage1;
    reg [7:0] cnt_next_stage1;
    reg       valid_stage1;
    
    // Pipeline stage 2 - Comparison logic
    reg [7:0] cnt_stage2;
    reg       comparison_result_stage2;
    reg       valid_stage2;
    
    // Pipeline stage 3 - Output generation
    reg       out_next_stage3;
    reg       valid_stage3;
    
    // Pipeline stage 1: Counter logic
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            cnt_next_stage1 = (cnt_stage1 == HIGH+LOW-1) ? 8'd0 : cnt_stage1 + 8'd1;
            cnt_stage1 <= cnt_next_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Comparison logic
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_stage2 <= 8'd0;
            comparison_result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            cnt_stage2 <= cnt_stage1;
            comparison_result_stage2 <= (cnt_stage1 < HIGH-1) || (cnt_stage1 == HIGH+LOW-1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Output generation
    always @(posedge clk) begin
        if (!rst_n) begin
            out_next_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            out <= 1'b0;
        end else begin
            out_next_stage3 <= comparison_result_stage2;
            valid_stage3 <= valid_stage2;
            if (valid_stage3) begin
                out <= out_next_stage3;
            end
        end
    end
endmodule