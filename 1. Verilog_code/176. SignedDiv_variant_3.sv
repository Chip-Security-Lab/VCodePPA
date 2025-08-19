//SystemVerilog
module SignedDiv(
    input wire clk,
    input wire rst_n,
    input signed [7:0] num,
    input signed [7:0] den,
    output reg signed [7:0] q
);

    // Pipeline stage 1: Input validation and sign handling
    reg signed [7:0] num_reg;
    reg signed [7:0] den_reg;
    reg den_zero;
    reg sign_result;
    
    // Pipeline stage 2: Goldschmidt initialization
    reg signed [15:0] num_abs;
    reg signed [15:0] den_abs;
    reg signed [15:0] f;
    reg den_zero_reg;
    reg sign_result_reg;
    
    // Pipeline stage 3: Goldschmidt iteration 1
    reg signed [15:0] num_iter1;
    reg signed [15:0] den_iter1;
    reg signed [15:0] f_iter1;
    reg den_zero_reg2;
    reg sign_result_reg2;
    
    // Pipeline stage 4: Goldschmidt iteration 2
    reg signed [15:0] num_iter2;
    reg signed [15:0] den_iter2;
    reg den_zero_reg3;
    reg sign_result_reg3;
    
    // Pipeline stage 5: Final result
    reg signed [15:0] div_result;
    reg den_zero_reg4;
    reg sign_result_reg4;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_reg <= 8'd0;
            den_reg <= 8'd0;
            den_zero <= 1'b0;
            sign_result <= 1'b0;
        end else begin
            num_reg <= num;
            den_reg <= den;
            den_zero <= (den == 8'd0);
            sign_result <= (num[7] ^ den[7]);
        end
    end
    
    // Pipeline stage 2: Goldschmidt initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_abs <= 16'd0;
            den_abs <= 16'd0;
            f <= 16'd0;
            den_zero_reg <= 1'b0;
            sign_result_reg <= 1'b0;
        end else begin
            num_abs <= (num_reg[7]) ? -{8'd0, num_reg} : {8'd0, num_reg};
            den_abs <= (den_reg[7]) ? -{8'd0, den_reg} : {8'd0, den_reg};
            // Initial approximation: f = 2 - den_abs
            f <= 16'd2 - {8'd0, den_reg};
            den_zero_reg <= den_zero;
            sign_result_reg <= sign_result;
        end
    end
    
    // Pipeline stage 3: Goldschmidt iteration 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_iter1 <= 16'd0;
            den_iter1 <= 16'd0;
            f_iter1 <= 16'd0;
            den_zero_reg2 <= 1'b0;
            sign_result_reg2 <= 1'b0;
        end else begin
            num_iter1 <= num_abs * f;
            den_iter1 <= den_abs * f;
            f_iter1 <= 16'd2 - den_iter1;
            den_zero_reg2 <= den_zero_reg;
            sign_result_reg2 <= sign_result_reg;
        end
    end
    
    // Pipeline stage 4: Goldschmidt iteration 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_iter2 <= 16'd0;
            den_iter2 <= 16'd0;
            den_zero_reg3 <= 1'b0;
            sign_result_reg3 <= 1'b0;
        end else begin
            num_iter2 <= num_iter1 * f_iter1;
            den_iter2 <= den_iter1 * f_iter1;
            den_zero_reg3 <= den_zero_reg2;
            sign_result_reg3 <= sign_result_reg2;
        end
    end
    
    // Pipeline stage 5: Final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_result <= 16'd0;
            den_zero_reg4 <= 1'b0;
            sign_result_reg4 <= 1'b0;
        end else begin
            div_result <= num_iter2;
            den_zero_reg4 <= den_zero_reg3;
            sign_result_reg4 <= sign_result_reg3;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 8'h80;
        end else begin
            q <= den_zero_reg4 ? 8'h80 : 
                 (sign_result_reg4 ? -div_result[7:0] : div_result[7:0]);
        end
    end

endmodule