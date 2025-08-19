//SystemVerilog
module var_shift #(parameter W = 8) (
    input wire clock,
    input wire clear,
    input wire [W-1:0] data,
    input wire [2:0] shift_amt,
    input wire load,
    output wire [W-1:0] result
);
    reg [W-1:0] shift_reg;
    
    // Optimized control logic with priority encoding
    always @(posedge clock) begin
        if (clear)
            shift_reg <= {W{1'b0}};  // Clear has highest priority
        else if (load)
            shift_reg <= data;       // Load has second priority
        else begin
            // Optimized shifting using case statement for better PPA metrics
            case (shift_amt)
                3'd0: shift_reg <= shift_reg;
                3'd1: shift_reg <= {1'b0, shift_reg[W-1:1]};
                3'd2: shift_reg <= {2'b0, shift_reg[W-1:2]};
                3'd3: shift_reg <= {3'b0, shift_reg[W-1:3]};
                3'd4: shift_reg <= {4'b0, shift_reg[W-1:4]};
                3'd5: shift_reg <= {5'b0, shift_reg[W-1:5]};
                3'd6: shift_reg <= {6'b0, shift_reg[W-1:6]};
                3'd7: shift_reg <= {7'b0, shift_reg[W-1:7]};
                default: shift_reg <= shift_reg;
            endcase
        end
    end
    
    // Direct output assignment
    assign result = shift_reg;
endmodule