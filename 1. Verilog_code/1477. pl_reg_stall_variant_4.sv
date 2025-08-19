//SystemVerilog
module pl_reg_stall #(parameter W=4) (
    input clk, rst, load, stall,
    input [W-1:0] new_data,
    output reg [W-1:0] current_data
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_data <= {W{1'b0}};
        end else if (!stall && load) begin
            current_data <= new_data;
        end
        // No need for explicit "else" - register holds value by default
    end
    
endmodule