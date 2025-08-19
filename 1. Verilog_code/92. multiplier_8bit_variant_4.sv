//SystemVerilog
module multiplier_8bit (
    input wire clk,
    input wire rst_n,
    
    // Input interface - Valid-Ready handshake
    input wire [7:0] a,
    input wire [7:0] b,
    input wire valid_in,
    output reg ready_in,
    
    // Output interface - Valid-Ready handshake  
    output reg [15:0] product,
    output reg valid_out,
    input wire ready_out
);

    // Internal registers
    reg [15:0] product_reg;
    reg calc_done;
    
    // Input handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b0;
        end else begin
            ready_in <= !calc_done || (calc_done && ready_out);
        end
    end
    
    // Multiplication logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_reg <= 16'b0;
            calc_done <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            if (valid_in && ready_in) begin
                product_reg <= a * b;
                calc_done <= 1'b1;
                valid_out <= 1'b1;
            end else if (calc_done && ready_out) begin
                calc_done <= 1'b0;
                valid_out <= 1'b0;
            end
        end
    end
    
    // Output assignment
    assign product = product_reg;

endmodule