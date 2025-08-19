//SystemVerilog
module mult_sequential (
    input clk, start,
    input [7:0] multiplicand, multiplier,
    output reg [15:0] product,
    output reg done
);
    reg [3:0] count;
    wire count_done = (count == 4'd7);
    
    // Pipeline registers
    reg [15:0] product_buf;
    reg [7:0] multiplicand_buf;
    reg [7:0] multiplier_buf;
    reg [15:0] product_pipe;
    reg [7:0] multiplicand_pipe;
    reg [7:0] multiplier_pipe;
    reg [15:0] product_temp;
    reg [7:0] multiplicand_temp;
    reg [7:0] multiplier_temp;
    
    // First stage: Input buffering
    always @(posedge clk) begin
        multiplicand_temp <= multiplicand;
        multiplier_temp <= multiplier;
    end
    
    // Second stage: Pipeline register
    always @(posedge clk) begin
        multiplicand_pipe <= multiplicand_temp;
        multiplier_pipe <= multiplier_temp;
    end
    
    // Third stage: Main computation
    always @(posedge clk) begin
        if(start) begin
            product_pipe <= {8'b0, multiplier_pipe};
            count <= 4'd0;
            done <= 1'b0;
        end else if(!done) begin
            product_pipe[15:8] <= product_pipe[15:8] + (product_pipe[0] ? multiplicand_pipe : 8'b0);
            product_pipe <= {1'b0, product_pipe[15:1]};
            count <= count + 1'b1;
            done <= count_done;
        end
    end
    
    // Fourth stage: Output buffering
    always @(posedge clk) begin
        product_buf <= product_pipe;
    end
    
    // Final stage: Output
    always @(posedge clk) begin
        product <= product_buf;
    end
endmodule