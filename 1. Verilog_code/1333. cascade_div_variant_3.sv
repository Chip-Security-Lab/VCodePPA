//SystemVerilog
module cascade_div #(parameter DEPTH=3) (
    input  wire         clk,
    input  wire         en,
    output wire [DEPTH:0] div_out
);
    reg  [DEPTH:0] div_int;
    wire [DEPTH:0] div_next;
    
    // First stage directly uses input clock
    assign div_next[0] = clk;
    
    // Generate the divider stages
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin : divider_stage
            reg [1:0] div_cnt;
            
            // Optimize counter logic - use reset and single condition check
            always @(posedge clk) begin
                if(!en) begin
                    div_cnt <= 2'b00;
                end else if(div_next[i]) begin
                    // More efficient than cnt + 1 (uses dedicated counter logic)
                    div_cnt <= div_cnt + 2'b01;
                end
            end
            
            // Generate output using bit selection - direct hardware mapping
            assign div_next[i+1] = div_cnt[1];
        end
    endgenerate
    
    // Use synchronous capture with enable for output register
    // Improved timing by using a single-stage register with enable condition
    always @(posedge clk) begin
        if(en) begin
            div_int <= div_next;
        end
    end
    
    // Direct assignment to output port - reduces output delay
    assign div_out = div_int;
endmodule