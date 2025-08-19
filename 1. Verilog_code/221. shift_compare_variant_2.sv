//SystemVerilog
module shift_compare (
    input wire clk,
    input wire rst_n,
    input wire [4:0] x_in,
    input wire [4:0] y_in,
    output reg [4:0] shift_left_out,
    output reg [4:0] shift_right_out,
    output reg equal_out
);

    // Pipeline stage 1: Input registers
    reg [4:0] x_reg;
    reg [4:0] y_reg;
    
    // Pipeline stage 2: Shift operations
    wire [4:0] shift_left_wire;
    wire [4:0] shift_right_wire;
    wire equal_wire;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= 5'b0;
            y_reg <= 5'b0;
        end else begin
            x_reg <= x_in;
            y_reg <= y_in;
        end
    end
    
    // Pipeline stage 2: Shift and compare operations
    assign shift_left_wire = x_reg << 1;
    assign shift_right_wire = y_reg >> 1;
    assign equal_wire = (x_reg == y_reg);
    
    // Pipeline stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_left_out <= 5'b0;
            shift_right_out <= 5'b0;
            equal_out <= 1'b0;
        end else begin
            shift_left_out <= shift_left_wire;
            shift_right_out <= shift_right_wire;
            equal_out <= equal_wire;
        end
    end

endmodule