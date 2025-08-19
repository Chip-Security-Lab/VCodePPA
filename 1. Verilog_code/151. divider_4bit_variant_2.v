module divider_4bit (
    input wire clk,
    input wire rst_n,
    input wire [3:0] a,
    input wire [3:0] b,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    reg [3:0] a_reg;
    reg [3:0] b_reg;
    reg [3:0] quotient_reg;
    reg [3:0] remainder_reg;
    
    // LUT for division
    reg [7:0] div_lut [0:255];
    reg [7:0] div_result;
    
    // Initialize LUT
    integer i;
    initial begin
        for(i = 0; i < 256; i = i + 1) begin
            if(i[3:0] == 0) begin
                div_lut[i] = 8'h00;
            end else begin
                div_lut[i] = {i[7:4] / i[3:0], i[7:4] % i[3:0]};
            end
        end
    end

    // Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // LUT-based division
    always @(*) begin
        div_result = div_lut[{a_reg, b_reg}];
    end

    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient <= 4'b0;
            remainder <= 4'b0;
        end else begin
            quotient <= div_result[7:4];
            remainder <= div_result[3:0];
        end
    end

endmodule