//SystemVerilog
module priority_load_reg(
    input clk, rst_n,
    input [7:0] data_a, data_b, data_c,
    input load_a, load_b, load_c,
    output reg [7:0] result
);
    // Register input data and control signals
    reg [7:0] data_a_reg, data_b_reg, data_c_reg;
    reg load_a_reg, load_b_reg, load_c_reg;
    
    // First stage: register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg <= 8'h00;
            data_b_reg <= 8'h00;
            data_c_reg <= 8'h00;
            load_a_reg <= 1'b0;
            load_b_reg <= 1'b0;
            load_c_reg <= 1'b0;
        end
        else begin
            data_a_reg <= data_a;
            data_b_reg <= data_b;
            data_c_reg <= data_c;
            load_a_reg <= load_a;
            load_b_reg <= load_b;
            load_c_reg <= load_c;
        end
    end
    
    // Second stage: priority selection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 8'h00;
        else if (load_a_reg)      // Highest priority
            result <= data_a_reg;
        else if (load_b_reg)      // Medium priority
            result <= data_b_reg;
        else if (load_c_reg)      // Lowest priority
            result <= data_c_reg;
    end
endmodule