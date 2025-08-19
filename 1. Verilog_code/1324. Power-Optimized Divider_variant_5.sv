//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module power_opt_divider (
    input wire clock_i, 
    input wire nreset_i, 
    input wire enable_i,
    output wire clock_o
);
    // Newton-Raphson divider state
    reg [2:0] iter_cnt;
    reg div_out;
    
    // Newton-Raphson approximation values
    reg [2:0] divisor;
    reg [2:0] x_approx;
    reg [5:0] temp_product;
    reg iteration_done;
    
    // Buffered signals for better power/timing
    reg div_out_buf;
    reg iteration_done_buf;
    
    // Newton-Raphson iteration logic
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            iter_cnt <= 3'b000;
            div_out <= 1'b0;
            div_out_buf <= 1'b0;
            divisor <= 3'b001; // Initial divisor
            x_approx <= 3'b100; // Initial approximation
            temp_product <= 6'b000000;
            iteration_done <= 1'b0;
            iteration_done_buf <= 1'b0;
        end else if (enable_i) begin
            // Buffer signals for better driving
            iteration_done_buf <= iteration_done;
            div_out_buf <= div_out;
            
            // Newton-Raphson iteration: x_n+1 = x_n * (2 - D * x_n)
            // For 3-bit implementation, we use simplified approach
            if (iter_cnt == 3'b000) begin
                // Initialize iteration
                temp_product <= divisor * x_approx;
                iter_cnt <= iter_cnt + 1'b1;
            end else if (iter_cnt == 3'b001) begin
                // Calculate 2 - D * x_n (simplified)
                x_approx <= x_approx + ((temp_product[2:0] ^ 3'b111) + 3'b001);
                iter_cnt <= iter_cnt + 1'b1;
            end else if (iter_cnt < 3'b111) begin
                // Additional iterations to refine result
                iter_cnt <= iter_cnt + 1'b1;
            end else begin
                // Final iteration
                iteration_done <= 1'b1;
                iter_cnt <= 3'b000;
                div_out <= ~div_out;
                divisor <= divisor + 1'b1;  // Update divisor for next cycle
                x_approx <= 3'b100;  // Reset approximation
            end
        end
    end
    
    // Output clock generation
    assign clock_o = div_out_buf & enable_i;
endmodule

`default_nettype wire