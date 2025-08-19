//SystemVerilog
module pl_reg_async_load #(parameter W=8) (
    input clk, rst_n, load,
    input [W-1:0] async_data,
    output [W-1:0] q
);
    reg [W-1:0] q_reg;
    
    // Main register logic with direct load signal usage
    // Removed the input registers and applied the inputs directly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_reg <= {W{1'b0}};
        end else if (load) begin
            q_reg <= async_data;
        end
    end

    // Output assignment
    assign q = q_reg;
endmodule