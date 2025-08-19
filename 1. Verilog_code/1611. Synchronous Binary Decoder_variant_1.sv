//SystemVerilog
module sync_binary_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [OUT_WIDTH-1:0] sel_out
);

    // Pipeline registers
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [OUT_WIDTH-1:0] decode_reg;
    
    // Intermediate signals for conditional inversion subtraction
    reg [OUT_WIDTH-1:0] base_value;
    reg [OUT_WIDTH-1:0] inverted_value;
    reg [OUT_WIDTH-1:0] result;
    
    // Address register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_reg <= addr;
        end
    end
    
    // Decode stage with conditional inversion subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_reg <= {OUT_WIDTH{1'b0}};
            base_value <= {OUT_WIDTH{1'b0}};
            inverted_value <= {OUT_WIDTH{1'b0}};
            result <= {OUT_WIDTH{1'b0}};
        end else begin
            // Initialize base value to all 1's
            base_value <= {OUT_WIDTH{1'b1}};
            
            // Calculate inverted value based on address
            inverted_value <= ~({OUT_WIDTH{1'b1}} - (1'b1 << addr_reg));
            
            // Select result based on address value
            if (addr_reg == {ADDR_WIDTH{1'b0}}) begin
                result <= {OUT_WIDTH{1'b0}};
            end else begin
                result <= base_value - inverted_value;
            end
            
            // Final decode result
            decode_reg <= result;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out <= {OUT_WIDTH{1'b0}};
        end else begin
            sel_out <= decode_reg;
        end
    end

endmodule