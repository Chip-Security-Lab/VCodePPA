//SystemVerilog
module band_pass_filter #(
    parameter WIDTH = 12
)(
    input clk, arst,
    input [WIDTH-1:0] x_in,
    output reg [WIDTH-1:0] y_out
);

    // Pipeline stage 1: Input and subtraction
    reg [WIDTH-1:0] x_in_reg;
    reg [WIDTH-1:0] lp_out_reg;
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;
    
    // Pipeline stage 2: Shift operation
    reg [WIDTH-1:0] diff_reg;
    wire [WIDTH-1:0] shifted_diff;
    
    // Pipeline stage 3: Low-pass accumulation
    reg [WIDTH-1:0] shifted_diff_reg;
    wire [WIDTH-1:0] lp_next;
    
    // Pipeline stage 4: High-pass calculation
    reg [WIDTH-1:0] lp_out;
    wire [WIDTH-1:0] hp_temp;
    wire [WIDTH:0] hp_borrow;
    
    // Pipeline stage 5: Output
    reg [WIDTH-1:0] hp_out;
    
    // Stage 1: Input and subtraction
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            x_in_reg <= 0;
            lp_out_reg <= 0;
        end else begin
            x_in_reg <= x_in;
            lp_out_reg <= lp_out;
        end
    end
    
    // 借位减法器实现
    assign borrow[0] = 0;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_subtract
            assign diff[i] = x_in_reg[i] ^ lp_out_reg[i] ^ borrow[i];
            assign borrow[i+1] = (~x_in_reg[i] & lp_out_reg[i]) | (~x_in_reg[i] & borrow[i]) | (lp_out_reg[i] & borrow[i]);
        end
    endgenerate
    
    // Stage 2: Shift operation
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            diff_reg <= 0;
        end else begin
            diff_reg <= diff;
        end
    end
    
    assign shifted_diff = diff_reg >>> 3;
    
    // Stage 3: Low-pass accumulation
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            shifted_diff_reg <= 0;
        end else begin
            shifted_diff_reg <= shifted_diff;
        end
    end
    
    assign lp_next = lp_out_reg + shifted_diff_reg;
    
    // Stage 4: Low-pass update and high-pass calculation
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            lp_out <= 0;
        end else begin
            lp_out <= lp_next;
        end
    end
    
    // 使用借位减法器实现高通滤波计算
    assign hp_borrow[0] = 0;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : hp_borrow_subtract
            assign hp_temp[i] = x_in_reg[i] ^ lp_out[i] ^ hp_borrow[i];
            assign hp_borrow[i+1] = (~x_in_reg[i] & lp_out[i]) | (~x_in_reg[i] & hp_borrow[i]) | (lp_out[i] & hp_borrow[i]);
        end
    endgenerate
    
    // Stage 5: High-pass update and output
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            hp_out <= 0;
            y_out <= 0;
        end else begin
            hp_out <= hp_temp;
            y_out <= hp_out;
        end
    end
endmodule