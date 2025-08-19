//SystemVerilog
module frac_delete_div #(parameter ACC_WIDTH=8) (
    input clk, rst,
    output reg clk_out
);
    reg [ACC_WIDTH-1:0] acc;
    wire [ACC_WIDTH-1:0] sum;
    
    // Han-Carlson adder implementation
    wire [ACC_WIDTH-1:0] p, g;           // Propagate and generate signals
    wire [ACC_WIDTH-1:0] pp, gg;         // Preprocessed signals
    wire [ACC_WIDTH-1:0] pc, gc;         // Postprocessed signals
    
    // Step 1: Preprocessing - Generate p and g signals
    assign p = acc | 8'd3;
    assign g = acc & 8'd3;
    
    // Step 2: First parallel prefix computation (even bits)
    assign pp[0] = p[0];
    assign gg[0] = g[0];
    
    assign pp[2] = p[2] & p[1];
    assign gg[2] = g[2] | (p[2] & g[1]);
    
    assign pp[4] = p[4] & p[3];
    assign gg[4] = g[4] | (p[4] & g[3]);
    
    assign pp[6] = p[6] & p[5];
    assign gg[6] = g[6] | (p[6] & g[5]);
    
    // Step 3: Second parallel prefix computation (odd bits)
    assign pc[0] = pp[0];
    assign gc[0] = gg[0];
    
    assign pc[1] = p[1] & pp[0];
    assign gc[1] = g[1] | (p[1] & gg[0]);
    
    assign pc[2] = pp[2];
    assign gc[2] = gg[2];
    
    assign pc[3] = p[3] & pp[2];
    assign gc[3] = g[3] | (p[3] & gg[2]);
    
    assign pc[4] = pp[4];
    assign gc[4] = gg[4];
    
    assign pc[5] = p[5] & pp[4];
    assign gc[5] = g[5] | (p[5] & gg[4]);
    
    assign pc[6] = pp[6];
    assign gc[6] = gg[6];
    
    assign pc[7] = p[7] & pp[6];
    assign gc[7] = g[7] | (p[7] & gg[6]);
    
    // Step 4: Final carries calculation
    wire [ACC_WIDTH:0] carries;
    assign carries[0] = 1'b0;
    
    // Generate carries using the prefix results
    genvar i;
    generate
        for (i = 0; i < ACC_WIDTH; i = i + 1) begin : carry_gen
            assign carries[i+1] = gc[i] | (pc[i] & carries[i]);
        end
    endgenerate
    
    // Step 5: Calculate sum
    assign sum = p ^ {carries[ACC_WIDTH-1:0]};
    
    always @(posedge clk) begin
        if(rst) begin
            acc <= 0;
            clk_out <= 0;
        end else begin
            acc <= sum;  // Using Han-Carlson adder result
            clk_out <= (acc < 8'h80) ? 1'b1 : 1'b0;
        end
    end
endmodule