//SystemVerilog
module cascade_div #(parameter DEPTH=3) (
    input wire clk,
    input wire en,
    output wire [DEPTH:0] div_out
);
    // Pipeline registers for clock division signals
    reg [DEPTH:0] clk_div_stage1;
    reg [DEPTH:0] clk_div_stage2;
    reg [DEPTH:0] clk_div_stage3;
    
    // Pipeline valid signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Base clock signal
    wire [DEPTH:0] clk_div;
    assign clk_div[0] = clk;
    
    // Output assignment
    assign div_out = clk_div_stage3;
    
    // Pipeline stage control
    always @(posedge clk) begin
        if (!en) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            clk_div_stage1 <= {(DEPTH+1){1'b0}};
            clk_div_stage2 <= {(DEPTH+1){1'b0}};
            clk_div_stage3 <= {(DEPTH+1){1'b0}};
        end else begin
            // First pipeline stage
            valid_stage1 <= 1'b1;
            clk_div_stage1[0] <= clk_div[0];
            
            // Second pipeline stage
            valid_stage2 <= valid_stage1;
            clk_div_stage2 <= clk_div_stage1;
            
            // Third pipeline stage
            valid_stage3 <= valid_stage2;
            clk_div_stage3 <= clk_div_stage2;
        end
    end
    
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin : stage
            // Divide-by-4 counter for each stage
            reg [1:0] cnt_stage1;
            reg [1:0] cnt_stage2;
            reg [1:0] cnt_next;
            
            // Pipelined counter with Brent-Kung adder structure
            wire p0, g0;        // Propagate and generate for bit 0
            wire p1, g1;        // Propagate and generate for bit 1
            wire g0_1;          // Group generate term
            
            // Compute next counter value with Brent-Kung structure
            always @(*) begin
                if (valid_stage1) begin
                    // Implement Brent-Kung addition logic
                    cnt_next[0] = ~cnt_stage1[0];                 // XOR with 1
                    cnt_next[1] = cnt_stage1[1] ^ cnt_stage1[0];  // Carry propagation to bit 1
                end else begin
                    cnt_next = 2'b00;
                end
            end
            
            // Pipeline stage 1 - sample input and compute
            always @(posedge clk_div[i]) begin
                if (!en) begin
                    cnt_stage1 <= 2'b00;
                end else begin
                    cnt_stage1 <= cnt_next;
                end
            end
            
            // Pipeline stage 2 - register computed values
            always @(posedge clk) begin
                if (!en) begin
                    cnt_stage2 <= 2'b00;
                end else if (valid_stage1) begin
                    cnt_stage2 <= cnt_stage1;
                end
            end
            
            // Clock division output
            assign clk_div[i+1] = cnt_stage2[1];
        end
    endgenerate
endmodule