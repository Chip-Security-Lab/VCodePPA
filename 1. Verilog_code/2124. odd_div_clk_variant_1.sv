//SystemVerilog
module odd_div_clk #(
    parameter N = 5
)(
    input clk_in,
    input reset,
    output clk_div
);
    reg [2:0] posedge_counter;
    reg [2:0] negedge_counter;
    reg clk_p, clk_n;
    
    // LUT for division calculation - precomputed (N-1)/2 values for 3-bit width
    reg [2:0] div_threshold;
    
    // LUT implementation using if-else cascaded structure
    always @(*) begin
        if (N == 3'd1) begin
            div_threshold = 3'd0;
        end else if (N == 3'd2) begin
            div_threshold = 3'd0;
        end else if (N == 3'd3) begin
            div_threshold = 3'd1;
        end else if (N == 3'd4) begin
            div_threshold = 3'd1;
        end else if (N == 3'd5) begin
            div_threshold = 3'd2;
        end else if (N == 3'd6) begin
            div_threshold = 3'd2;
        end else if (N == 3'd7) begin
            div_threshold = 3'd3;
        end else begin
            div_threshold = 3'd2; // Default for N=5
        end
    end
    
    // Posedge counter
    always @(posedge clk_in) begin
        if (reset) begin
            posedge_counter <= 3'd0;
            clk_p <= 1'b0;
        end else begin
            if (posedge_counter >= div_threshold) begin
                posedge_counter <= 3'd0;
                clk_p <= ~clk_p;
            end else begin
                posedge_counter <= posedge_counter + 1'b1;
            end
        end
    end
    
    // Negedge counter
    always @(negedge clk_in) begin
        if (reset) begin
            negedge_counter <= 3'd0;
            clk_n <= 1'b0;
        end else begin
            if (negedge_counter >= div_threshold) begin
                negedge_counter <= 3'd0;
                clk_n <= ~clk_n;
            end else begin
                negedge_counter <= negedge_counter + 1'b1;
            end
        end
    end
    
    assign clk_div = clk_p | clk_n;
endmodule