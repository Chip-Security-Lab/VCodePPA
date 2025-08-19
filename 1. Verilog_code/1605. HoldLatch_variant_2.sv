//SystemVerilog
module HoldLatch #(parameter W=4) (
    input clk,
    input rst_n, 
    input hold,
    input [W-1:0] d,
    output reg [W-1:0] q
);

    // Pipeline registers
    reg [W-1:0] d_reg;
    reg hold_reg;
    reg valid_reg;
    
    // Combinational logic signals
    wire [W-1:0] next_d;
    wire next_valid;
    
    // Next state logic
    assign next_d = hold_reg ? d_reg : d;
    assign next_valid = 1'b1;
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_reg <= {W{1'b0}};
            hold_reg <= 1'b0;
            valid_reg <= 1'b0;
            q <= {W{1'b0}};
        end else begin
            d_reg <= next_d;
            hold_reg <= hold;
            valid_reg <= next_valid;
            q <= d_reg;
        end
    end

endmodule