//SystemVerilog
module shift_compare (
    input wire clk,
    input wire rst_n,
    input wire [4:0] x,
    input wire [4:0] y,
    output reg [4:0] shift_left,
    output reg [4:0] shift_right, 
    output reg equal
);

    // Pipeline stage 1: Input registration
    reg [4:0] x_reg;
    reg [4:0] y_reg;
    
    // Pipeline stage 2: Shift operations
    reg [4:0] shift_left_next;
    reg [4:0] shift_right_next;
    reg equal_next;

    // Stage 1: Input registration for x
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= 5'b0;
        end else begin
            x_reg <= x;
        end
    end

    // Stage 1: Input registration for y
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_reg <= 5'b0;
        end else begin
            y_reg <= y;
        end
    end

    // Stage 2: Shift left operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_left <= 5'b0;
        end else begin
            shift_left <= shift_left_next;
        end
    end

    // Stage 2: Shift right operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_right <= 5'b0;
        end else begin
            shift_right <= shift_right_next;
        end
    end

    // Stage 2: Equal comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal <= 1'b0;
        end else begin
            equal <= equal_next;
        end
    end

    // Combinational logic for shift left operation
    always @(*) begin
        shift_left_next = x_reg << 1;
    end

    // Combinational logic for shift right operation
    always @(*) begin
        shift_right_next = y_reg >> 1;
    end

    // Combinational logic for equal comparison
    always @(*) begin
        equal_next = (x_reg == y_reg);
    end

endmodule