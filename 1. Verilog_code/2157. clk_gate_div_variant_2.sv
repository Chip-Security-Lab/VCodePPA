//SystemVerilog
module clk_gate_div #(parameter DIV=2) (
    input clk, en,
    output reg clk_out
);
    // Counter register 
    reg [7:0] cnt;
    
    // Direct comparison signals without pipeline registers
    wire cnt_eq_div_minus1;
    wire cnt_eq_zero;
    
    // Next state signals
    reg [7:0] next_cnt;
    reg next_clk_out;
    
    // Direct comparisons
    assign cnt_eq_div_minus1 = (cnt == DIV-1);
    assign cnt_eq_zero = (cnt == 8'd0);
    
    // Next state logic using direct comparison results
    always @(*) begin
        case (cnt_eq_div_minus1)
            1'b1: next_cnt = 8'd0;
            1'b0: next_cnt = cnt + 1'b1;
            default: next_cnt = cnt + 1'b1;
        endcase
        
        case (cnt_eq_zero)
            1'b1: next_clk_out = ~clk_out;
            1'b0: next_clk_out = clk_out;
            default: next_clk_out = clk_out;
        endcase
    end
    
    // Main register update
    always @(posedge clk) begin
        if(en) begin
            cnt <= next_cnt;
            clk_out <= next_clk_out;
        end
    end
endmodule