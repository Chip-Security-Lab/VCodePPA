//SystemVerilog
module window_div #(parameter L=5, H=12) (
    input wire clk,
    input wire rst_n,
    output reg clk_out
);
    // Counter register
    reg [7:0] cnt;
    
    // Counter logic in separate always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'b0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
    
    // Comparison signals
    wire comp_lower;
    wire comp_upper;
    wire window_result;
    
    // Combinational comparison logic
    assign comp_lower = (cnt >= L);
    assign comp_upper = (cnt <= H);
    assign window_result = comp_lower & comp_upper;
    
    // Pipeline stage 1 register
    reg window_result_stage1;
    
    // Pipeline stage 1 logic in separate always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            window_result_stage1 <= 1'b0;
        end else begin
            window_result_stage1 <= window_result;
        end
    end
    
    // Output generation in separate always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= window_result_stage1;
        end
    end

endmodule