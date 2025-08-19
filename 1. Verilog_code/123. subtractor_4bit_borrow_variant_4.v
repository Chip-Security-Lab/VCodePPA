module subtractor_4bit_borrow (
    input wire clk,
    input wire rst_n,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] diff,
    output reg borrow
);

    // Pipeline stage 1: Input registers
    reg [3:0] a_reg;
    reg [3:0] b_reg;
    
    // Pipeline stage 2: Complement calculation
    reg [3:0] b_comp_reg;
    wire [3:0] b_comp = ~b_reg + 1'b1;
    
    // Pipeline stage 3: Addition
    reg [3:0] sum_reg;
    reg carry_out_reg;
    wire [4:0] add_result = a_reg + b_comp_reg;
    
    // Pipeline stage 4: Output
    reg [3:0] diff_reg;
    reg borrow_reg;

    // Pipeline stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Pipeline stage 2: Complement calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_comp_reg <= 4'b0;
        end else begin
            b_comp_reg <= b_comp;
        end
    end

    // Pipeline stage 3: Addition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg <= 4'b0;
            carry_out_reg <= 1'b0;
        end else begin
            {carry_out_reg, sum_reg} <= add_result;
        end
    end

    // Pipeline stage 4: Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 4'b0;
            borrow <= 1'b0;
        end else begin
            diff <= sum_reg;
            borrow <= ~carry_out_reg;
        end
    end

endmodule