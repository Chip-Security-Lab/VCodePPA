//SystemVerilog
module mixed_precision_mult (
    input wire clk,
    input wire rst_n,
    input wire valid,
    output wire ready,
    input wire [7:0] A,
    input wire [3:0] B,
    output reg [11:0] Result
);

    reg [11:0] result_reg;
    reg valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 12'b0;
            valid_reg <= 1'b0;
        end else begin
            if (valid && ready) begin
                result_reg <= A * B;
                valid_reg <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end
    
    assign ready = !valid_reg;
    assign Result = result_reg;
    
endmodule