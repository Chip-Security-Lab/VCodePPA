//SystemVerilog
module multiplier_high_priority (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire valid,
    output wire ready,
    output wire [15:0] product
);

    // Pipeline stage registers
    reg [7:0] a_reg, b_reg;
    reg [15:0] mult_result;
    reg [15:0] result_reg;
    reg result_valid;
    
    // Control signals
    wire mult_enable;
    wire result_update;
    
    // Ready signal generation
    assign ready = ~result_valid;
    
    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'd0;
            b_reg <= 8'd0;
        end else if (valid && ready) begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Multiplication stage
    assign mult_enable = valid && ready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result <= 16'd0;
        end else if (mult_enable) begin
            mult_result <= a_reg * b_reg;
        end
    end
    
    // Output stage
    assign result_update = mult_enable;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 16'd0;
            result_valid <= 1'b0;
        end else begin
            if (result_update) begin
                result_reg <= mult_result;
                result_valid <= 1'b1;
            end else if (result_valid) begin
                result_valid <= 1'b0;
            end
        end
    end
    
    // Output assignment
    assign product = result_reg;

endmodule